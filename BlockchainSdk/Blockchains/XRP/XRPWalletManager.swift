//
//  XRPWalletManager.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSdk
import TangemLocalization

class XRPWalletManager: BaseManager, WalletManager {
    var txBuilder: XRPTransactionBuilder!
    var networkService: XRPNetworkService!

    var currentHost: String { networkService.host }

    /// Established trustlines fetched from the XRP wallet response.
    private var establishedTrustlines = Set<XRPTrustLine>()

    /// The timestamp of the most recent attempt to open a trustline on the Stellar network.
    /// This is used to track the timing of user-initiated trustline creation requests.
    ///
    /// Since XRP uses a unified wallet and manager for both the native coin and all tokens,
    /// this timestamp helps avoid race conditions or duplicate operations during trustline setup.
    ///
    /// We assume that a trustline transaction will be finished within 10 seconds of setting this timestamp.
    private var lastTrustlineOpenAttemptDate: Date?

    override func update(completion: @escaping (Result<Void, Error>) -> Void) {
        cancellable = networkService
            .getInfo(account: wallet.address)
            .sink(receiveCompletion: { [weak self] completionSubscription in
                if case .failure(let error) = completionSubscription {
                    self?.wallet.clearAmounts()
                    completion(.failure(error))
                }
            }, receiveValue: { [weak self] response in
                self?.updateWallet(with: response)
                completion(.success(()))
            })
    }

    private func updateWallet(with response: XrpInfoResponse) {
        var trustlineCount: Decimal = 0

        switch response.trustlines {
        case .success(let trustlines):
            trustlineCount = Decimal(trustlines.count)
            establishedTrustlines = Set(trustlines)
        case .failure:
            establishedTrustlines = []
        }

        let trustlineReserve = trustlineCount * Constants.ownerReserveIncrement
        let utils = XRPAmountConverter(blockchain: wallet.blockchain)

        let totalReserve = utils.convertFromDrops(response.reserve) + trustlineReserve
        let availableBalance = utils.convertFromDrops(response.balance) - totalReserve

        wallet.add(reserveValue: totalReserve)
        wallet.add(coinValue: availableBalance)

        txBuilder.account = wallet.address

        if response.balance != response.unconfirmedBalance {
            if wallet.pendingTransactions.isEmpty {
                wallet.addDummyPendingTransaction()
            }
        } else {
            wallet.clearPendingTransaction()
        }

        for token in cardTokens {
            switch response.trustlines {
            case .success:
                // If the trustline exists, extract the balance.
                // If it's missing, we treat it as zero — this is a normal case for unopened trustlines.
                do {
                    let (currency, issuer) = try XRPAssetIdParser().getCurrencyCodeAndIssuer(from: token.contractAddress)
                    let stringBalance = XRPTrustlineUtils.balance(in: establishedTrustlines, currency: currency, issuer: issuer)
                    let balance = Decimal(stringValue: stringBalance) ?? 0.0
                    wallet.add(tokenValue: balance, for: token)
                } catch {
                    // If the asset format is invalid, we skip balance assignment.
                    wallet.clearAmount(for: token)
                }

            case .failure:
                // Trustline fetch failed — clear the balance to reflect an error state in the UI.
                wallet.clearAmount(for: token)
            }
        }
    }

    private func decodeAddress(address: String) -> String {
        do {
            return try XRPAddress.decodeXAddress(xAddress: address).rAddress
        } catch {
            return address
        }
    }

    private func signAndSend(
        transaction: Transaction,
        signer: TransactionSigner,
        xrpTransaction: XRPTransaction,
        hash: Data,
    ) -> AnyPublisher<TransactionSendResult, SendTxError> {
        signer.sign(hash: hash, walletPublicKey: wallet.publicKey)
            .withWeakCaptureOf(self)
            .tryMap { manager, hash in
                let rawTransactionHash = try manager.txBuilder.buildForSend(transaction: xrpTransaction, signature: hash)
                return rawTransactionHash
            }
            .withWeakCaptureOf(self)
            .flatMap { manager, rawTransactionHash -> AnyPublisher<TransactionSendResult, Error> in
                manager.networkService.send(blob: rawTransactionHash)
                    .tryMap { [weak manager] hash in
                        let mapper = PendingTransactionRecordMapper()
                        let record = mapper.mapToPendingTransactionRecord(transaction: transaction, hash: hash)
                        manager?.wallet.addPendingTransaction(record)
                        return TransactionSendResult(hash: hash)
                    }
                    .mapAndEraseSendTxError(tx: rawTransactionHash)
                    .eraseToAnyPublisher()
            }
            .mapSendTxError()
            .eraseToAnyPublisher()
    }

    private func signAndSubmitTrustSetTransaction(
        fee: Fee,
        signer: any TransactionSigner,
        token: Token
    ) -> AnyPublisher<Void, Error> {
        let transaction = Transaction(
            amount: .zeroToken(token: token),
            fee: fee,
            sourceAddress: wallet.address,
            destinationAddress: wallet.address,
            changeAddress: "",
            contractAddress: token.contractAddress
        )

        let decodedAddress = decodeAddress(address: transaction.destinationAddress)
        return networkService.getSequence(account: decodedAddress)
            .withWeakCaptureOf(self)
            .tryMap { manager, sequence in
                let enrichedTransaction = manager.enrichTransaction(transaction, withSequence: sequence)
                let txAndHash = try manager.txBuilder.buildTrustSetTransactionForSign(transaction: enrichedTransaction)
                return txAndHash
            }
            .withWeakCaptureOf(self)
            .flatMap { manager, txAndHash in
                let (xrpTransaction, hash) = txAndHash
                let publisher = manager.signAndSend(transaction: transaction, signer: signer, xrpTransaction: xrpTransaction, hash: hash)
                return publisher
                    .handleEvents(receiveCompletion: { [weak manager] in
                        if case .failure = $0 {
                            manager?.lastTrustlineOpenAttemptDate = nil
                        }
                    })
                    .mapToVoid()
                    .mapError { $0 as Error }
            }
            .eraseToAnyPublisher()
    }

    private func checkTrustlineAndSendToken(
        token: Token,
        transaction: Transaction,
        signer: TransactionSigner,
        xrpTransaction: XRPTransaction,
        hash: Data
    ) -> AnyPublisher<TransactionSendResult, SendTxError> {
        networkService.getAccountTrustlines(account: decodeAddress(address: transaction.destinationAddress))
            .tryMap { result in
                let trustlines = try result.get()
                let (currency, issuer) = try XRPAssetIdParser().getCurrencyCodeAndIssuer(from: token.contractAddress)

                if !XRPTrustlineUtils.containsTrustline(in: trustlines, currency: currency, issuer: issuer) {
                    throw BlockchainSdkError.noTrustlineAtDestination
                }
            }
            .mapSendTxError()
            .withWeakCaptureOf(self)
            .flatMap { manager, _ in
                manager.signAndSend(
                    transaction: transaction,
                    signer: signer,
                    xrpTransaction: xrpTransaction,
                    hash: hash
                )
            }
            .eraseToAnyPublisher()
    }
}

extension XRPWalletManager: TransactionSender {
    var allowsFeeSelection: Bool { true }

    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<TransactionSendResult, SendTxError> {
        return networkService
            .getSequence(account: decodeAddress(address: transaction.sourceAddress))
            .withWeakCaptureOf(self)
            .tryMap { manager, sequence in
                let enrichedTx = manager.enrichTransaction(transaction, withSequence: sequence)
                let txBuiltForSign = try manager.txBuilder.buildForSign(transaction: enrichedTx)
                return txBuiltForSign
            }
            .mapSendTxError()
            .withWeakCaptureOf(self)
            .flatMap { manager, txBuiltForSign in
                let (xrpTransaction, hash) = txBuiltForSign

                if case .token(let token) = transaction.amount.type {
                    return manager.checkTrustlineAndSendToken(
                        token: token,
                        transaction: transaction,
                        signer: signer,
                        xrpTransaction: xrpTransaction,
                        hash: hash
                    )
                }

                return manager.signAndSend(
                    transaction: transaction,
                    signer: signer,
                    xrpTransaction: xrpTransaction,
                    hash: hash
                )
            }
            .eraseToAnyPublisher()
    }

    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee], Error> {
        return networkService.getFee()
            .map { [weak self] xrpFeeResponse -> [Fee] in
                guard let self else { return [] }
                let blockchain = wallet.blockchain
                let utils = XRPAmountConverter(blockchain: blockchain)

                let min = utils.convertFromDrops(xrpFeeResponse.min)
                let normal = utils.convertFromDrops(xrpFeeResponse.normal)
                let max = utils.convertFromDrops(xrpFeeResponse.max)

                let minFee = Amount(with: blockchain, value: min)
                let normalFee = Amount(with: blockchain, value: normal)
                let maxFee = Amount(with: blockchain, value: max)

                return [minFee, normalFee, maxFee].map { Fee($0) }
            }
            .eraseToAnyPublisher()
    }

    private func enrichTransaction(_ transaction: Transaction, withSequence sequence: Int) -> Transaction {
        var mutableTransaction = transaction

        if var existingParams = mutableTransaction.params as? XRPTransactionParams {
            existingParams.sequence = sequence
            mutableTransaction.params = existingParams
        } else {
            mutableTransaction.params = XRPTransactionParams(sequence: sequence)
        }

        return mutableTransaction
    }
}

extension XRPWalletManager: ThenProcessable {}

extension XRPWalletManager: ReserveAmountRestrictable {
    func validateReserveAmount(amount: Amount, address: String) async throws {
        let reserveAmount = Amount(with: wallet.blockchain, value: Constants.minAmountToCreateCoinAccount)
        let addressDecoded = decodeAddress(address: address)
        let isAccountCreated = try await networkService.checkAccountCreated(account: addressDecoded).async()
        let trustlines = try await networkService.getAccountTrustlines(account: addressDecoded).async().get()

        switch amount.type {
        case .coin where !isAccountCreated && amount.value < Constants.minAmountToCreateCoinAccount:
            throw ValidationError.reserve(amount: reserveAmount)

        case .token where !isAccountCreated:
            throw ValidationError.reserve(amount: reserveAmount)

        case .token(let token):
            let (currency, issuer) = try XRPAssetIdParser().getCurrencyCodeAndIssuer(from: token.contractAddress)
            if !XRPTrustlineUtils.containsTrustline(in: trustlines, currency: currency, issuer: issuer) {
                throw ValidationError.noTrustlineAtDestination
            }

        case .reserve, .feeResource, .coin:
            break
        }
    }
}

extension XRPWalletManager: RequiredMemoRestrictable {
    func validateRequiredMemo(destination: String, transactionParams: TransactionParams?) async throws {
        if let transactionParams = transactionParams as? XRPTransactionParams, transactionParams.destinationTag != nil {
            return
        }

        let isMemoRequired = try await networkService.checkAccountDestinationTag(account: destination).async()

        // This error will work if the destination parameters are not received, and the recipient's account requires the tag after verification.
        if isMemoRequired {
            throw ValidationError.destinationMemoRequired
        }
    }
}

// MARK: - AssetRequirementsManager protocol conformance

extension XRPWalletManager: AssetRequirementsManager {
    func feeStatusForRequirement(asset: Asset) -> AnyPublisher<AssetRequirementFeeStatus, Never> {
        networkService.getFee()
            .replaceError(with: .init(min: .zero, normal: .zero, max: .zero))
            .map {
                $0.normal
            }
            .withWeakCaptureOf(self)
            .map { manager, fee in
                let feeBalance = manager.wallet.feeCurrencyBalance(amountType: .coin)
                let feeInDrops = XRPAmountConverter(blockchain: manager.wallet.blockchain).convertFromDrops(fee)
                let totalRequired = Self.Constants.ownerReserveIncrement + feeInDrops

                if feeBalance > totalRequired {
                    return .sufficient
                } else {
                    let missingAmount = (totalRequired - feeBalance)
                        .rounded(blockchain: manager.wallet.blockchain)
                        .decimalNumber
                        .description(withLocale: Locale.posixEnUS)

                    return .insufficient(missingAmount: missingAmount)
                }
            }
            .eraseToAnyPublisher()
    }

    func requirementsCondition(for asset: Asset) -> AssetRequirementsCondition? {
        // If more than 10 seconds have passed, assume the trustline transaction has completed and clear the timestamp
        if let startDate = lastTrustlineOpenAttemptDate, Date().timeIntervalSince(startDate) > 10 {
            lastTrustlineOpenAttemptDate = nil
        }

        switch asset {
        case .token(let token):
            guard !XRPTrustlineUtils.containsTrustline(in: establishedTrustlines, for: token) else {
                return nil
            }

            // Used to determine whether to disable the "Open Trustline" button in the UI
            let isTrustlineOperationInProgress = lastTrustlineOpenAttemptDate != nil || wallet.hasPendingTx

            // The base reserve (1 XRP) and reserves for existing entries are already accounted for.
            // This value represents only the incremental reserve required for the new entry.
            let reserveAmount = Amount(with: wallet.blockchain, value: Constants.ownerReserveIncrement)

            return .requiresTrustline(blockchain: wallet.blockchain, trustlineReserve: reserveAmount, isProcessing: isTrustlineOperationInProgress)
        case .coin, .reserve, .feeResource:
            return nil
        }
    }

    func fulfillRequirements(for asset: Asset, signer: any TransactionSigner) -> AnyPublisher<Void, Error> {
        guard case .token(let token) = asset else {
            assertionFailure("Asset must be `.token` to proceed with trustline operation.")
            return Fail(error: BlockchainSdkError.failedToBuildTx).eraseToAnyPublisher()
        }

        lastTrustlineOpenAttemptDate = Date()

        return networkService.getFee()
            .tryMap { response -> Decimal in
                response.normal
            }
            .withWeakCaptureOf(self)
            .flatMap { manager, fee in
                let fee = Fee(Amount(with: manager.wallet.blockchain, value: fee))
                return manager.signAndSubmitTrustSetTransaction(fee: fee, signer: signer, token: token)
            }
            .eraseToAnyPublisher()
    }
}

extension XRPWalletManager {
    enum Constants {
        /// Incremental reserve required per owned object (trustline, offer, etc.) on XRPL.
        /// This amount (0.2 XRP) is added for each additional ledger entry owned by the account.
        /// https://xrpl.org/reserves.html
        static let ownerReserveIncrement: Decimal = .init(stringValue: "0.2")!

        /// 1 XRP
        static let minAmountToCreateCoinAccount: Decimal = 1
    }
}
