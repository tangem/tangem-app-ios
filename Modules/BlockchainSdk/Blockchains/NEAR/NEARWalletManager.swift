//
//  NEARWalletManager.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation
import TangemLocalization

final class NEARWalletManager: BaseWalletManager {
    private let networkService: NEARNetworkService

    private let transactionBuilder: NEARTransactionBuilder

    /// Contains an actual NEAR protocol configuration, fetched once per app session.
    /// - Warning: Don't use directly, use `getProtocolConfig()` instance method to get the most recent protocol config.
    private let protocolConfigCache: NEARProtocolConfigCache

    init(
        wallet: Wallet,
        networkService: NEARNetworkService,
        transactionBuilder: NEARTransactionBuilder,
        protocolConfigCache: NEARProtocolConfigCache
    ) {
        self.networkService = networkService
        self.transactionBuilder = transactionBuilder
        self.protocolConfigCache = protocolConfigCache
        super.init(wallet: wallet)
    }

    @available(*, unavailable)
    override init(wallet: Wallet) {
        fatalError("\(#function) has not been implemented")
    }

    func updateWalletManager(address: String) async throws {
        let accountId = address
        let transactionHashes = wallet.pendingTransactions.map(\.hash)

        do {
            async let protocolConfig = getProtocolConfig().async()
            async let accountInfo = networkService.getInfo(accountId: accountId).async()
            async let transactionsInfo = networkService.getTransactionsInfo(accountId: accountId, transactionHashes: transactionHashes).async()

            switch try await accountInfo {
            case .notInitialized:
                let config = try await protocolConfig
                throw makeNoAccountError(using: config)
            case .initialized(let account):
                try await updateWallet(account: account, transactionsInfo: transactionsInfo, protocolConfig: protocolConfig)
            }
        } catch {
            wallet.clearAmounts()
            throw error
        }
    }

    private func updateWallet(
        account: NEARAccountInfo.Account,
        transactionsInfo: NEARTransactionsInfo,
        protocolConfig: NEARProtocolConfig
    ) {
        let decimalValue = wallet.blockchain.decimalValue
        let reserveValue = account.storageUsageInBytes * protocolConfig.storageAmountPerByte / decimalValue
        wallet.add(reserveValue: reserveValue)

        let coinValue = max(account.amount.value - reserveValue, .zero)
        wallet.add(coinValue: coinValue)

        let completedTransactionHashes = transactionsInfo.transactions
            .filter { $0.status != .other }
            .map(\.result.hash)
            .toSet()
        wallet.removePendingTransaction(where: completedTransactionHashes.contains(_:))
    }

    private func updateWalletWithPendingTransaction(_ transaction: Transaction, sendResult: TransactionSendResult) {
        let mapper = PendingTransactionRecordMapper()
        let hash = sendResult.hash
        let pendingTransaction = mapper.mapToPendingTransactionRecord(transaction: transaction, hash: hash)

        wallet.addPendingTransaction(pendingTransaction)
    }

    private func makeNoAccountError(using protocolConfig: NEARProtocolConfig) -> BlockchainSdkError {
        let networkName = wallet.blockchain.displayName
        let decimalValue = wallet.blockchain.decimalValue
        let reserveValue = Constants.accountDefaultStorageUsageInBytes * protocolConfig.storageAmountPerByte / decimalValue
        let reserveValueString = reserveValue.decimalNumber.stringValue
        let currencySymbol = wallet.blockchain.currencySymbol
        let errorMessage = Localization.noAccountGeneric(networkName, reserveValueString, currencySymbol)

        return BlockchainSdkError.noAccount(message: errorMessage, amountToCreate: reserveValue)
    }

    /// - Note: Never fails; if a network request fails, the local fallback value will be used.
    private func getProtocolConfig() -> AnyPublisher<NEARProtocolConfig, Never> {
        return Deferred { [weak self, networkService] in
            if let protocolConfig = self?.protocolConfigCache.get() {
                return Just(protocolConfig)
                    .eraseToAnyPublisher()
            }

            return networkService
                .getProtocolConfig()
                .replaceError(with: NEARProtocolConfig.fallbackProtocolConfig)
                .handleEvents(receiveOutput: { self?.protocolConfigCache.set($0) })
                .eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
    }
}

// MARK: - WalletManager protocol conformance

extension NEARWalletManager: WalletManager {
    var currentHost: String { networkService.host }

    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee], Error> {
        return Publishers.CombineLatest(
            getProtocolConfig().setFailureType(to: Error.self),
            networkService.getGasPrice()
        )
        .withWeakCaptureOf(self)
        .map { walletManager, input in
            let (protocolConfig, gasPrice) = input
            let blockchain = walletManager.wallet.blockchain

            let feeCalculator = NEARFeeCalculator(
                protocolConfig: protocolConfig,
                gasPrice: gasPrice,
                decimalValue: blockchain.decimalValue
            )

            let feeValue = feeCalculator.calculateFee(
                source: walletManager.wallet.address,
                destination: destination
            )

            return [Fee(Amount(with: blockchain, value: feeValue))]
        }
        .eraseToAnyPublisher()
    }

    func send(
        _ transaction: Transaction,
        signer: TransactionSigner
    ) -> AnyPublisher<TransactionSendResult, SendTxError> {
        return networkService
            .getAccessKeyInfo(accountId: wallet.address, publicKey: wallet.publicKey)
            .tryMap { accessKeyInfo -> NEARAccessKeyInfo in
                guard accessKeyInfo.canBeUsedForTransfer else {
                    throw BlockchainSdkError.failedToBuildTx
                }

                return accessKeyInfo
            }
            .withWeakCaptureOf(self)
            .map { walletManager, accessKeyInfo in
                return NEARTransactionParams(
                    publicKey: walletManager.wallet.publicKey,
                    currentNonce: accessKeyInfo.currentNonce,
                    recentBlockHash: accessKeyInfo.recentBlockHash
                )
            }
            .withWeakCaptureOf(self)
            .tryMap { walletManager, transactionParams -> (Data, NEARTransactionParams) in
                let transaction = transaction.then { $0.params = transactionParams }
                let hash = try walletManager.transactionBuilder.buildForSign(transaction: transaction)

                return (hash, transactionParams)
            }
            .flatMap { hash, transactionParams in
                let signaturePublisher = signer.sign(hash: hash, walletPublicKey: transactionParams.publicKey)
                let transactionParamsPublisher = Just(transactionParams).setFailureType(to: Error.self)

                return Publishers.Zip(signaturePublisher, transactionParamsPublisher)
            }
            .withWeakCaptureOf(self)
            .tryMap { walletManager, input in
                let (signature, transactionParams) = input
                let transaction = transaction.then { $0.params = transactionParams }

                return try walletManager.transactionBuilder.buildForSend(transaction: transaction, signature: signature.signature)
            }
            .withWeakCaptureOf(self)
            .flatMap { walletManager, rawTransactionData in
                return walletManager.networkService
                    .send(transaction: rawTransactionData)
                    .mapAndEraseSendTxError(
                        tx: rawTransactionData.hex(),
                        currentHost: walletManager.currentHost
                    )
            }
            .mapSendTxError(currentHost: currentHost)
            .handleEvents(
                receiveOutput: { [weak self] sendResult in
                    self?.updateWalletWithPendingTransaction(transaction, sendResult: sendResult)
                }
            )
            .eraseToAnyPublisher()
    }
}

// MARK: - AddressResolver protocol conformance

extension NEARWalletManager: AddressResolver {
    func resolve(_ address: String) async throws -> AddressResolverResult {
        // Implicit accounts don't require any modification or verification
        guard requiresResolution(address: address) else {
            return AddressResolverResult(resolved: address)
        }

        // Here we're verifying if the account with the given named account ID exists
        // and just throwing an error if it doesn't
        let resolved: String = try await withCheckedThrowingContinuation { continuation in
            var getInfoSubscription: AnyCancellable?

            getInfoSubscription = networkService
                .getInfo(accountId: address)
                .tryMap { accountInfo in
                    switch accountInfo {
                    case .notInitialized:
                        throw BlockchainSdkError.empty // The particular type of this error doesn't matter
                    case .initialized(let account):
                        return account
                    }
                }
                .sink(
                    receiveCompletion: { result in
                        switch result {
                        case .failure(let error):
                            continuation.resume(throwing: error)
                        case .finished:
                            continuation.resume(returning: address)
                        }
                        withExtendedLifetime(getInfoSubscription) {}
                    },
                    receiveValue: { _ in }
                )
        }
        return AddressResolverResult(resolved: resolved)
    }

    func requiresResolution(address: String) -> Bool {
        !NEARAddressUtil.isImplicitAccount(accountId: address)
    }
}

// MARK: - Constants

private extension NEARWalletManager {
    enum Constants {
        /// For existing accounts this value can be fetched using the `view_account` RPC API endpoint.
        ///
        /// For newly created implicit accounts with a single access key (the default) we have to use this constant.
        /// See https://docs.near.org/integrator/accounts and
        /// https://pages.near.org/papers/economics-in-sharded-blockchain/#transaction-and-storage-fees for details.
        static let accountDefaultStorageUsageInBytes: Decimal = 182
    }
}
