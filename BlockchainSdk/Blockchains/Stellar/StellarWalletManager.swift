//
//  StellarWalletmanager.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import stellarsdk
import Combine
import TangemSdk
import TangemLocalization

enum StellarError: Int, Error, LocalizedError {
    // WARNING: Make sure to preserve the error codes when removing or inserting errors

    case emptyResponse
    case requiresMemo
    case failedToFindLatestLedger
    case xlmCreateAccount
    case assetCreateAccount
    case assetNoAccountOnDestination
    case assetNoTrustline

    // WARNING: Make sure to preserve the error codes when removing or inserting errors

    var errorDescription: String? {
        let blockchain = Blockchain.stellar(curve: .ed25519, testnet: false)
        let networkName = blockchain.displayName
        let symbol = blockchain.currencySymbol

        switch self {
        case .requiresMemo:
            return Localization.genericRequiresMemoError
        case .xlmCreateAccount, .assetCreateAccount:
            return Localization.noAccountGeneric(networkName, "\(StellarWalletManager.Constants.minAmountToCreateCoinAccount)", "\(symbol)")
        case .assetNoAccountOnDestination:
            return Localization.sendErrorNoTargetAccount("\(StellarWalletManager.Constants.minAmountToCreateCoinAccount) \(symbol)")
        case .assetNoTrustline:
            return Localization.noTrustlineXlmAsset
        default:
            return Localization.genericErrorCode(errorCodeDescription)
        }
    }

    private var errorCodeDescription: String {
        "stellar_error \(rawValue)"
    }
}

extension StellarWalletManager {
    enum Constants {
        /// Base reserve currently defined by the Stellar network (0.5 XLM)
        static let baseReserve: Decimal = .init(stringValue: "0.5")!
        /// 1 XLM
        static let minAmountToCreateCoinAccount: Decimal = 1
        /// 1.5 XLM
        static let minAmountToCreateAssetAccount: Decimal = .init(stringValue: "1.5")!
    }
}

class StellarWalletManager: BaseManager, WalletManager {
    typealias Asset = Amount.AmountType
    typealias StellarAsset = Asset

    var txBuilder: StellarTransactionBuilder!
    var networkService: StellarNetworkService!
    var currentHost: String { networkService.host }

    private var trustlines = [Trustline]()
    private var assetsOpeningTrustline = Set<String>()

    override func update(completion: @escaping (Result<Void, Error>) -> Void) {
        cancellable = networkService
            .getInfo(accountId: wallet.address, isAsset: !cardTokens.isEmpty)
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

    private func signAndSend(
        transaction: Transaction,
        signer: TransactionSigner,
        buildPublisher: AnyPublisher<(hash: Data, transaction: stellarsdk.TransactionXDR), Error>
    ) -> AnyPublisher<TransactionSendResult, SendTxError> {
        buildPublisher
            .withWeakCaptureOf(self)
            .flatMap { manager, buildForSignResponse -> AnyPublisher<(Data, (hash: Data, transaction: stellarsdk.TransactionXDR)), Error> in
                signer.sign(hash: buildForSignResponse.hash, walletPublicKey: manager.wallet.publicKey)
                    .map { ($0, buildForSignResponse) }
                    .eraseToAnyPublisher()
            }
            .tryMap { [weak self] result throws -> String in
                guard let self else { throw BlockchainSdkError.empty }

                guard let tx = self.txBuilder.buildForSend(signature: result.0, transaction: result.1.transaction) else {
                    throw BlockchainSdkError.failedToBuildTx
                }

                return tx
            }
            .flatMap { [weak self] rawTransactionHash -> AnyPublisher<TransactionSendResult, Error> in
                self?.networkService.send(transaction: rawTransactionHash).tryMap { [weak self] hash in
                    guard let self = self else { throw BlockchainSdkError.empty }

                    let mapper = PendingTransactionRecordMapper()
                    let record = mapper.mapToPendingTransactionRecord(transaction: transaction, hash: hash)
                    wallet.addPendingTransaction(record)
                    return TransactionSendResult(hash: hash)
                }
                .mapAndEraseSendTxError(tx: rawTransactionHash)
                .eraseToAnyPublisher() ?? .emptyFail
            }
            .mapSendTxError()
            .eraseToAnyPublisher()
    }

    private func signAndSendChangeTrustTransaction(
        fee: Amount,
        signer: any TransactionSigner,
        token: Token?,
        limit: ChangeTrustOperation.ChangeTrustLimit
    ) -> AnyPublisher<Void, Error> {
        guard let token else {
            return Fail(error: BlockchainSdkError.failedToBuildTx).eraseToAnyPublisher()
        }

        let transaction = Transaction(
            amount: .zeroToken(token: token),
            fee: Fee(fee),
            sourceAddress: wallet.address,
            destinationAddress: wallet.address,
            changeAddress: "",
            contractAddress: token.contractAddress
        )

        return signAndSend(
            transaction: transaction,
            signer: signer,
            buildPublisher: txBuilder.buildChangeTrustOperationForSign(transaction: transaction, limit: limit)
        )
        .handleEvents(
            receiveCompletion: { [weak self] completion in
                if case .failure = completion {
                    self?.assetsOpeningTrustline.remove(token.contractAddress)
                }
            }
        )
        .withWeakCaptureOf(self)
        .mapToVoid()
        .mapError { $0 as Error }
        .eraseToAnyPublisher()
    }

    private func updateWallet(with response: StellarResponse) {
        txBuilder.sequence = response.sequence
        let assetBalancesCount = response.assetBalances.count
        let fullReserve = response.baseReserve * Decimal(assetBalancesCount + 2)

        wallet.add(reserveValue: fullReserve)
        wallet.add(coinValue: response.balance - fullReserve)

        if cardTokens.isEmpty {
            response.assetBalances.forEach {
                let token = Token(
                    name: $0.code,
                    symbol: $0.code,
                    contractAddress: $0.issuer,
                    decimalCount: wallet.blockchain.decimalCount
                )
                wallet.add(tokenValue: $0.balance, for: token)
            }
        } else {
            for token in cardTokens {
                let assetBalance = response.assetBalances.first(where: { $0.code == token.symbol })?.balance ?? 0.0
                wallet.add(tokenValue: assetBalance, for: token)
            }
        }

        trustlines = response.assetBalances.map { Trustline(assetCode: $0.code, issuer: $0.issuer) }

        // We believe that a transaction will be confirmed within 10 seconds
        let date = Date(timeIntervalSinceNow: -10)
        wallet.removePendingTransaction(older: date)
    }
}

extension StellarWalletManager: TransactionSender {
    var allowsFeeSelection: Bool { true }

    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<TransactionSendResult, SendTxError> {
        let buildPublisher = networkService
            .checkTargetAccount(address: transaction.destinationAddress, token: transaction.amount.type.token)
            .flatMap { [weak self] response -> AnyPublisher<(hash: Data, transaction: stellarsdk.TransactionXDR), Error> in
                guard let self else { return .emptyFail }
                return txBuilder.buildForSign(targetAccountResponse: response, transaction: transaction)
            }
            .eraseToAnyPublisher()

        return signAndSend(transaction: transaction, signer: signer, buildPublisher: buildPublisher)
    }

    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee], Error> {
        networkService.getFee()
            .map { $0.map { Fee($0) } }
            .eraseToAnyPublisher()
    }
}

extension StellarWalletManager: ThenProcessable {}

extension StellarWalletManager: ReserveAmountRestrictable {
    func validateReserveAmount(amount: Amount, addressType: ReserveAmountRestrictableAddressType) async throws {
        let isAccountCreated: Bool = try await {
            switch addressType {
            case .notCreated:
                return false
            case .address(let address):
                let account = try await networkService.checkTargetAccount(address: address, token: amount.type.token).async()
                return account.accountCreated
            }
        }()

        guard !isAccountCreated else {
            return
        }

        let reserveAmount = Amount(with: wallet.blockchain, value: Constants.minAmountToCreateCoinAccount)
        switch amount.type {
        case .coin:
            if amount < reserveAmount {
                throw ValidationError.reserve(amount: reserveAmount)
            }
        case .token:
            // From TxBuilder
            throw StellarError.assetNoAccountOnDestination
        case .reserve, .feeResource:
            break
        }
    }
}

extension StellarWalletManager: RequiredMemoRestrictable {
    func validateRequiredMemo(destination: String, transactionParams: (any TransactionParams)?) async throws {
        if let transactionParams = transactionParams as? StellarTransactionParams, transactionParams.memo != nil {
            return
        }

        do {
            let isMemoRequired = try await networkService.checkIsMemoRequired(for: destination).async()

            if isMemoRequired {
                throw ValidationError.destinationMemoRequired
            }

        } catch HorizonRequestError.notFound {
            // If the destination account is not created, we can't check that a memo is required
        }
    }
}

// MARK: - AssetRequirementsManager protocol conformance

extension StellarWalletManager: AssetRequirementsManager {
    func hasSufficientFeeBalance(for requirementsCondition: AssetRequirementsCondition?, on asset: Asset) -> Bool {
        guard case .token = asset, case .requiresTrustline(_, let fee, _) = requirementsCondition else {
            assertionFailure("Asset must be .token and condition must be .requiresTrustline to check Stellar trustline fee.")
            return false
        }

        let balance = wallet.feeCurrencyBalance(amountType: .coin)
        return balance >= fee.value
    }

    func requirementsCondition(for asset: Asset) -> AssetRequirementsCondition? {
        switch asset {
        case .token(let token):
            guard let codeAndIssuer = StellarAssetIdParser().getAssetCodeAndIssuer(from: token.contractAddress),
                  !trustlines.contains(where: { $0.assetCode == codeAndIssuer.assetCode && $0.issuer == codeAndIssuer.issuer })
            else {
                assetsOpeningTrustline.remove(token.contractAddress)
                return nil
            }

            let isTrustlineOperationInProgress = assetsOpeningTrustline.contains(token.contractAddress)

            // Base reserve calculation reference: https://developers.stellar.org/docs/learn/fundamentals/lumens#minimum-balance
            // We only show the base reserve here (0.5 XLM), because the account already exists,
            // and the initial 1 XLM reserve (2 × base) and reserves for existing trustlines are already locked.
            let feeAmount = Amount(with: wallet.blockchain, value: Constants.baseReserve)

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

        assetsOpeningTrustline.insert(token.contractAddress)

        return networkService.getFee()
            .tryMap { fees -> Amount in
                guard let p80Fee = fees[safe: 1] else {
                    throw BlockchainSdkError.failedToGetFee
                }

                return p80Fee
            }
            .withWeakCaptureOf(self)
            .flatMap { manager, fee in
                manager.signAndSendChangeTrustTransaction(fee: fee, signer: signer, token: asset.token, limit: .max)
            }
            .eraseToAnyPublisher()
    }
}

private extension StellarWalletManager {
    struct Trustline {
        let assetCode: String
        let issuer: String
    }
}
