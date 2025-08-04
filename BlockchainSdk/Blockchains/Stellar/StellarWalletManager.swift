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
    case failedParseAssetId

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
        /// Stellar accounts must maintain a minimum balance to exist, which is calculated using the base reserve.
        /// An account must always maintain a minimum balance of two base reserves (currently 1 XLM).
        /// https://developers.stellar.org/docs/learn/fundamentals/lumens
        static let baseEntryCount: Int = 2
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

    /// Established trustlines fetched from the Stellar wallet response.
    private var establishedTrustlines = [StellarAssetResponse]()

    /// Assets that are currently undergoing the trustline creation process in the Stellar network.
    /// This set holds asset identifiers (currency code + issuer) that have initiated the trustline setup
    /// but are not yet confirmed.
    ///
    /// Since Stellar also uses a single wallet and manager for both the native coin and all tokens,
    /// multiple tokens may be in the process of opening trustlines simultaneously.
    private var tokensOpeningTrustline = Set<StellarAssetResponse>()

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
        hash: Data,
        transactionXDR: TransactionXDR
    ) -> AnyPublisher<TransactionSendResult, SendTxError> {
        signer.sign(hash: hash, walletPublicKey: wallet.publicKey)
            .tryMap { [weak self] signature -> String in
                guard let self else { throw BlockchainSdkError.empty }
                guard let tx = txBuilder.buildForSend(signature: signature, transaction: transactionXDR) else {
                    throw BlockchainSdkError.failedToBuildTx
                }
                return tx
            }
            .flatMap { [weak self] rawTransactionHash -> AnyPublisher<TransactionSendResult, Error> in
                self?.networkService.send(transaction: rawTransactionHash).tryMap { hash in
                    guard let self = self else { throw BlockchainSdkError.empty }

                    let mapper = PendingTransactionRecordMapper()
                    let record = mapper.mapToPendingTransactionRecord(transaction: transaction, hash: hash)
                    self.wallet.addPendingTransaction(record)
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

        return Result { try txBuilder.buildChangeTrustOperationForSign(transaction: transaction, limit: limit) }
            .publisher
            .withWeakCaptureOf(self)
            .flatMap { manager, result in
                let (hash, transactionXDR) = result

                return manager.signAndSend(
                    transaction: transaction,
                    signer: signer,
                    hash: hash,
                    transactionXDR: transactionXDR
                )
                .handleEvents(receiveCompletion: { [weak manager] completion in
                    guard case .failure = completion,
                          let manager,
                          let (code, issuer) = try? StellarAssetIdParser().getAssetCodeAndIssuer(from: token.contractAddress),
                          let trustline = StellarTrustlineUtils.firstMatchingTrustline(
                              in: manager.tokensOpeningTrustline,
                              assetCode: code,
                              issuer: issuer
                          )
                    else {
                        return
                    }

                    manager.tokensOpeningTrustline.remove(trustline)
                })
                .mapToVoid()
                .mapError { $0 as Error }
                .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    private func updateWallet(with response: StellarResponse) {
        txBuilder.sequence = response.sequence
        let assetBalancesCount = response.assetBalances.count
        let fullReserve = response.baseReserve * Decimal(assetBalancesCount + Constants.baseEntryCount)

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
                // If balance is nil, trustline is not opened — treat as 0 balance
                let balance = StellarTrustlineUtils.firstMatchingTrustline(in: response.assetBalances, for: token)?.balance
                wallet.add(tokenValue: balance ?? 0.0, for: token)
            }
        }

        establishedTrustlines = response.assetBalances

        // We believe that a transaction will be confirmed within 10 seconds
        let date = Date(timeIntervalSinceNow: -10)
        wallet.removePendingTransaction(older: date)
    }
}

extension StellarWalletManager: TransactionSender {
    var allowsFeeSelection: Bool { true }

    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<TransactionSendResult, SendTxError> {
        networkService
            .checkTargetAccount(address: transaction.destinationAddress, token: transaction.amount.type.token)
            .withWeakCaptureOf(self)
            .tryMap { manager, response in
                let result = try manager.txBuilder.buildForSign(targetAccountResponse: response, transaction: transaction)
                return result
            }
            .withWeakCaptureOf(self)
            .mapSendTxError()
            .flatMap { manager, txBuiltForSign in
                let (hash, transactionXDR) = txBuiltForSign
                return manager.signAndSend(transaction: transaction, signer: signer, hash: hash, transactionXDR: transactionXDR)
            }
            .eraseToAnyPublisher()
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
            guard !StellarTrustlineUtils.containsTrustline(in: establishedTrustlines, for: token) else {
                if let trustline = StellarTrustlineUtils.firstMatchingTrustline(in: tokensOpeningTrustline, for: token) {
                    tokensOpeningTrustline.remove(trustline)
                }

                return nil
            }

            let isTrustlineOperationInProgress = StellarTrustlineUtils.containsTrustline(in: tokensOpeningTrustline, for: token)

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

        if let (code, issuer) = try? StellarAssetIdParser().getAssetCodeAndIssuer(from: token.contractAddress) {
            tokensOpeningTrustline.insert(.init(code: code, issuer: issuer, balance: .zero))
        }

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
