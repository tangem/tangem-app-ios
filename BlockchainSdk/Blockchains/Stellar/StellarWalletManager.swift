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
    private var establishedTrustlines = Set<StellarAssetResponse>()

    /// The timestamp of the most recent attempt to open a trustline on the Stellar network.
    /// This is used to track the timing of user-initiated trustline creation requests.
    ///
    /// Since Stellar uses a unified wallet and manager for both the native coin and all tokens,
    /// this timestamp helps avoid race conditions or duplicate operations during trustline setup.
    ///
    /// We assume that a trustline transaction will be finished within 10 seconds of setting this timestamp.
    private var lastTrustlineOpenAttemptDate: Date?

    override func updateWalletManager() async throws {
        do {
            let tokens = cardTokens
            let response = try await networkService
                .getInfo(accountId: wallet.address, isAsset: !tokens.isEmpty)
                .async()
            updateWallet(with: response, tokens: tokens)
        } catch {
            wallet.clearAmounts()
            throw error
        }
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
                    return TransactionSendResult(hash: hash, currentProviderHost: self.currentHost)
                }
                .mapAndEraseSendTxError(tx: rawTransactionHash, currentHost: self?.currentHost)
                .eraseToAnyPublisher() ?? .emptyFail
            }
            .mapSendTxError(currentHost: currentHost)
            .eraseToAnyPublisher()
    }

    private func signAndSendChangeTrustTransaction(
        fee: Amount,
        signer: any TransactionSigner,
        token: Token?,
        limit: ChangeTrustOperation.ChangeTrustLimit,
        sequenceNumber: Int64
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

        return Result {
            try txBuilder.buildChangeTrustOperationForSign(
                transaction: transaction,
                limit: limit,
                sequenceNumber: sequenceNumber
            )
        }
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
            .handleEvents(receiveCompletion: { [weak manager] in
                if case .failure = $0 {
                    manager?.lastTrustlineOpenAttemptDate = nil
                }
            })
            .mapToVoid()
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
    }

    private func updateWallet(with response: StellarResponse, tokens: [Token]) {
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
            for token in tokens {
                // If balance is nil, trustline is not opened — treat as 0 balance
                let balance = StellarTrustlineUtils.firstMatchingTrustline(in: response.assetBalances, for: token)?.balance
                wallet.add(tokenValue: balance ?? 0.0, for: token)
            }
        }

        establishedTrustlines = response.assetBalances.toSet()

        // We believe that a transaction will be confirmed within 10 seconds
        let date = Date(timeIntervalSinceNow: -10)
        wallet.removePendingTransaction(older: date)
    }
}

extension StellarWalletManager: TransactionSender {
    var allowsFeeSelection: Bool { true }

    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<TransactionSendResult, SendTxError> {
        let sequenceNumberPublisher = networkService.getSequenceNumber(for: wallet.address)
        let checkTargetAccountPublisher = networkService.checkTargetAccount(address: transaction.destinationAddress, token: transaction.amount.type.token)

        return Publishers.Zip(
            sequenceNumberPublisher,
            checkTargetAccountPublisher
        )
        .withWeakCaptureOf(self)
        .tryMap { manager, responses in
            let (sequenceNumber, targetAccountResponse) = responses

            let result = try manager.txBuilder
                .buildForSign(
                    targetAccountResponse: targetAccountResponse,
                    sequenceNumber: sequenceNumber,
                    transaction: transaction
                )

            return result
        }
        .withWeakCaptureOf(self)
        .mapSendTxError(currentHost: currentHost)
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
    func validateReserveAmount(amount: Amount, address: String) async throws {
        let account = try await networkService.checkTargetAccount(address: address, token: amount.type.token).async()
        let reserveAmount = Amount(with: wallet.blockchain, value: Constants.minAmountToCreateCoinAccount)

        switch amount.type {
        case .coin where !account.accountCreated && amount < reserveAmount:
            throw ValidationError.reserve(amount: reserveAmount)
        case .token where !account.accountCreated:
            throw ValidationError.reserve(amount: reserveAmount)
        case .token where !account.trustlineCreated:
            throw ValidationError.noTrustlineAtDestination
        case .reserve, .feeResource, .coin, .token:
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
    func feeStatusForRequirement(asset: Asset) -> AnyPublisher<AssetRequirementFeeStatus, Never> {
        networkService.getFee()
            .replaceError(with: [])
            .map {
                $0[safe: 1]?.value ?? .zero // p80 fee
            }
            .withWeakCaptureOf(self)
            .map { manager, fee in
                let feeBalance = manager.wallet.feeCurrencyBalance(amountType: .coin)
                let totalRequired = Self.Constants.baseReserve + fee

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
            guard !StellarTrustlineUtils.containsTrustline(in: establishedTrustlines, for: token) else {
                return nil
            }

            // Used to determine whether to disable the "Open Trustline" button in the UI
            let isTrustlineOperationInProgress = lastTrustlineOpenAttemptDate != nil || wallet.hasPendingTx

            // Base reserve calculation reference: https://developers.stellar.org/docs/learn/fundamentals/lumens#minimum-balance
            // We only show the base reserve here (0.5 XLM), because the account already exists,
            // and the initial 1 XLM reserve (2 × base) and reserves for existing trustlines are already locked.
            let requiredReserve = Amount(with: wallet.blockchain, value: Constants.baseReserve)

            return .requiresTrustline(
                blockchain: wallet.blockchain,
                trustlineReserve: requiredReserve,
                isProcessing: isTrustlineOperationInProgress
            )

        case .coin, .reserve, .feeResource:
            return nil
        }
    }

    func fulfillRequirements(for asset: Asset, signer: any TransactionSigner) -> AnyPublisher<Void, Error> {
        guard case .token = asset else {
            assertionFailure("Asset must be `.token` to proceed with trustline operation.")
            return Fail(error: BlockchainSdkError.failedToBuildTx).eraseToAnyPublisher()
        }

        lastTrustlineOpenAttemptDate = Date()

        let getFeePublisher = networkService.getFee()
        let sequencePublisher = networkService.getSequenceNumber(for: wallet.address)

        return Publishers.Zip(getFeePublisher, sequencePublisher)
            .tryMap { args -> (Amount, Int64) in
                let (fees, sequenceNumber) = args

                guard let p80Fee = fees[safe: 1] else {
                    throw BlockchainSdkError.failedToGetFee
                }

                return (p80Fee, sequenceNumber)
            }
            .withWeakCaptureOf(self)
            .flatMap { manager, args in
                let (fee, sequenceNumber) = args

                return manager.signAndSendChangeTrustTransaction(
                    fee: fee,
                    signer: signer,
                    token: asset.token,
                    limit: .max,
                    sequenceNumber: sequenceNumber
                )
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
