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

    /// Assets currently undergoing the trustline creation process.
    /// This set tracks token identifiers (currency code + issuer) that have initiated trustline setup,
    /// but have not yet completed it.
    ///
    /// Multiple tokens can be in this state simultaneously because XRP uses a single wallet and manager
    /// for both the main coin and all tokens.
    private var tokensOpeningTrustline = Set<String>()

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

    private func buildIfSufficientFunds(transaction: Transaction, isAccountCreated: Bool) throws -> (XRPTransaction, Data) {
        guard let walletReserve = wallet.amounts[.reserve] else {
            throw XRPError.missingReserve
        }

        if !isAccountCreated, transaction.amount.value < walletReserve.value {
            throw BlockchainSdkError.noAccount(
                message: Localization.sendErrorNoTargetAccount(walletReserve.value.stringValue),
                amountToCreate: walletReserve.value
            )
        }

        let buildResponse = try txBuilder.buildForSign(transaction: transaction)
        return buildResponse
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
                    .handleEvents(
                        receiveCompletion: { [weak manager] completion in
                            if case .failure = completion {
                                manager?.tokensOpeningTrustline.remove(token.contractAddress)
                            }
                        }
                    )
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
        Publishers.Zip(
            networkService.checkAccountCreated(account: decodeAddress(address: transaction.destinationAddress)),
            networkService.getSequence(account: decodeAddress(address: transaction.sourceAddress))
        )
        .withWeakCaptureOf(self)
        .tryMap { manager, results in
            let (isAccountCreated, sequence) = results
            let enrichedTx = manager.enrichTransaction(transaction, withSequence: sequence)
            let txBuiltForSign = try manager.buildIfSufficientFunds(transaction: enrichedTx, isAccountCreated: isAccountCreated)
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
            .eraseToAnyPublisher()
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
    func hasSufficientFeeBalance(for requirementsCondition: AssetRequirementsCondition?, on asset: Asset) -> Bool {
        guard case .token = asset, case .requiresTrustline(_, let fee, _) = requirementsCondition else {
            assertionFailure("Asset must be .token and condition must be .requiresTrustline to check XRP trustline fee.")
            return false
        }

        let balance = wallet.feeCurrencyBalance(amountType: .coin)
        return balance >= fee.value
    }

    func requirementsCondition(for asset: Asset) -> AssetRequirementsCondition? {
        switch asset {
        case .token(let token):
            guard let (currency, issuer) = try? XRPAssetIdParser().getCurrencyCodeAndIssuer(from: token.contractAddress),
                  !XRPTrustlineUtils.containsTrustline(in: establishedTrustlines, currency: currency, issuer: issuer)
            else {
                tokensOpeningTrustline.remove(token.contractAddress)
                return nil
            }

            let isTrustlineOperationInProgress = tokensOpeningTrustline.contains(token.contractAddress)

            // The base reserve (1 XRP) and reserves for existing entries are already accounted for.
            // This value represents only the incremental reserve required for the new entry.
            let feeAmount = Amount(with: wallet.blockchain, value: Constants.ownerReserveIncrement)

            return .requiresTrustline(blockchain: wallet.blockchain, fee: feeAmount, isProcessing: isTrustlineOperationInProgress)
        case .coin, .reserve, .feeResource:
            return nil
        }
    }

    func fulfillRequirements(for asset: Asset, signer: any TransactionSigner) -> AnyPublisher<Void, Error> {
        guard case .token(let token) = asset else {
            assertionFailure("Asset must be `.token` to proceed with trustline operation.")
            return Fail(error: BlockchainSdkError.failedToBuildTx).eraseToAnyPublisher()
        }

        tokensOpeningTrustline.insert(token.contractAddress)

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
