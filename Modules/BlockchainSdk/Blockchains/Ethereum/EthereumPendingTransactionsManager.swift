//
//  EthereumPendingTransactionsManager.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt

protocol EthereumPendingTransactionsManager {
    var pendingTransactionsPublisher: AnyPublisher<[PendingTransactionRecord], Never> { get }

    func syncPendingTransactions() async throws

    func addTransactions(_ transactions: [Transaction], hashes: [String])
}

final class CommonEthereumPendingTransactionsManager {
    private let walletAddress: String
    private let blockchain: Blockchain

    private let networkService: EthereumNetworkService
    private let networkServiceFactory: WalletNetworkServiceFactory
    private let dataStorage: BlockchainDataStorage
    private let mapper = PendingTransactionRecordMapper()
    private let addressConverter: EthereumAddressConverter

    private let providerNetworkServicesCache = NetworkServiceCache()

    private let pendingTransactionsSubject = CurrentValueSubject<[PendingTransactionRecord], Never>([])
    private var bag = Set<AnyCancellable>()

    private var pendingTransactionsCheckTask: Task<Void, Error>?

    init(
        walletAddress: String,
        blockchain: Blockchain,
        networkService: EthereumNetworkService,
        networkServiceFactory: WalletNetworkServiceFactory,
        dataStorage: BlockchainDataStorage,
        addressConverter: EthereumAddressConverter
    ) {
        self.walletAddress = walletAddress
        self.blockchain = blockchain
        self.networkService = networkService
        self.networkServiceFactory = networkServiceFactory
        self.dataStorage = dataStorage
        self.addressConverter = addressConverter

        let storedTransactions = getStoredTransactions()
        pendingTransactionsSubject.send(storedTransactions)

        if !storedTransactions.isEmpty {
            updatePendingTransactionsStatus()
        }

        bind()
    }
}

extension CommonEthereumPendingTransactionsManager: EthereumPendingTransactionsManager {
    var pendingTransactionsPublisher: AnyPublisher<[PendingTransactionRecord], Never> {
        pendingTransactionsSubject.eraseToAnyPublisher()
    }

    func syncPendingTransactions() async throws {
        BSDKLogger.debug("pending transactions to check: \(pendingTransactionsSubject.value)")

        let transactionsToCheck = pendingTransactionsSubject.value.filter { !$0.isDummy }

        let convertedAddress = try addressConverter.convertToETHAddress(walletAddress)

        async let pendingTxStatuses = fetchPendingTransactionStatuses(for: transactionsToCheck)
        async let pendingTransactionsCount = networkService.getPendingTxCount(convertedAddress).async()
        async let transactionsCount = networkService.getTxCount(convertedAddress).async()

        let (statuses, pendingTxCount, txCount) = try await (
            pendingTxStatuses,
            pendingTransactionsCount,
            transactionsCount
        )

        try Task.checkCancellation()

        // keep only those that are still pending.
        var pendingTransactions = transactionsToCheck.filter { transaction in
            guard let statusInfo = statuses[transaction] else {
                return true
            }

            let isProviderMismatch = statusInfo.provider != transaction.networkProviderType
            let isStatusDropped = statusInfo.status.isDropped
            let executionTimeoutExceeded = Date().timeIntervalSince(transaction.date) > Constants.transactionExecutionTimeout

            // keep transaction if it's executing in a private mempool
            // and status is unknown due to provider mismatch within execution timeout
            if let privateNetworkProviderType = transaction.networkProviderType,
               privateNetworkProviderType.isPrivateMempool,
               isProviderMismatch,
               isStatusDropped,
               !executionTimeoutExceeded {
                return true
            }
            return statuses[transaction]?.status.isPending == true
        }

        let localPendingCount = pendingTransactions.count

        // detect unknown/external pending transactions (pendingTransactionCount - transactionsCount)
        let nodePendingCount = max(0, pendingTxCount - txCount)

        if nodePendingCount > localPendingCount {
            // add dummy pending records for unknown pending transactions
            let dummy = mapper.makeDummy(blockchain: blockchain)
            pendingTransactions.append(dummy)
        } else {
            // remove dummy pending records if pending transactions count match
            pendingTransactions = pendingTransactions.filter { !$0.isDummy }
        }

        pendingTransactionsSubject.send(pendingTransactions)

        BSDKLogger.debug("pending transactions after update: \(pendingTransactionsSubject.value)")
    }

    func addTransactions(_ transactions: [Transaction], hashes: [String]) {
        precondition(transactions.count == hashes.count, "Transactions and hashes count mismatch")

        let existingHashes = Set(pendingTransactionsSubject.value.map(\.hash))

        let records = zip(transactions, hashes).compactMap { transaction, hash -> PendingTransactionRecord? in
            guard !existingHashes.contains(hash) else {
                return nil
            }

            return mapper.mapToPendingTransactionRecord(
                transaction: transaction,
                hash: hash,
                networkProviderType: networkService.networkProviderType
            )
        }

        var currentPendingTransactions = pendingTransactionsSubject.value
        currentPendingTransactions.append(contentsOf: records)

        pendingTransactionsSubject.send(currentPendingTransactions)

        // start status polling
        updatePendingTransactionsStatus()
    }
}

private extension CommonEthereumPendingTransactionsManager {
    func bind() {
        pendingTransactionsSubject
            .dropFirst()
            .sink { [weak self] transactions in
                self?.store(transactions: transactions)
            }
            .store(in: &bag)
    }

    var storageKey: String {
        let walletAddressPart = Data(hex: walletAddress).getSHA256().hexString

        return [
            walletAddressPart,
            blockchain.coinId,
            Constants.pendingTransactionsStorageKey,
        ].joined(separator: "_")
    }

    func store(transactions: [PendingTransactionRecord]) {
        let cachedTransactions = transactions.map { CachedPendingTransactionRecord(pendingTransactionRecord: $0) }
        dataStorage.store(
            key: storageKey,
            value: cachedTransactions,
        )
    }

    func getStoredTransactions() -> [PendingTransactionRecord] {
        let cachedTransactions: [CachedPendingTransactionRecord] = dataStorage.get(key: storageKey) ?? []
        return cachedTransactions.map { $0.pendingTransactionRecord }
    }

    func fetchPendingTransactionStatuses(
        for transactions: [PendingTransactionRecord]
    ) async throws -> [PendingTransactionRecord: PendingTransactionStatusInfo] {
        try await withThrowingTaskGroup(
            of: (PendingTransactionRecord, PendingTransactionStatusInfo).self
        ) { group in
            for transaction in transactions {
                group.addTask { [networkService, networkServiceFactory, blockchain, providerNetworkServicesCache] in
                    // Try to use provider-specific network service if available
                    if let providerType = transaction.networkProviderType,
                       providerType.isPrivateMempool {
                        // Get cached service or create new one
                        let providerNetworkService = await providerNetworkServicesCache.get(providerType) ??
                            networkServiceFactory.makeEthereumNetworkServiceIfAvailable(
                                for: blockchain,
                                with: providerType
                            )

                        if let providerNetworkService {
                            // Cache for future use
                            await providerNetworkServicesCache.set(providerNetworkService, for: providerType)

                            do {
                                let statusInfo = try await providerNetworkService.getTransactionByHash(transaction.hash).async()
                                return (transaction, statusInfo)
                            } catch {
                                // Fall back to default network service on error
                                BSDKLogger.debug("Failed to fetch status with specific provider for \(transaction.hash), error: \(error), switching to default provider")
                            }
                        }
                    }

                    // Use default network service
                    do {
                        let statusInfo = try await networkService.getTransactionByHash(transaction.hash).async()
                        return (transaction, statusInfo)
                    } catch {
                        BSDKLogger.debug("Failed to fetch status for \(transaction.hash): \(error)")
                        return (transaction, PendingTransactionStatusInfo(provider: networkService.networkProviderType, transaction: nil))
                    }
                }
            }

            var results: [PendingTransactionRecord: PendingTransactionStatusInfo] = [:]
            for try await (transaction, statusInfo) in group {
                results[transaction] = statusInfo
            }
            return results
        }
    }
}

/// Status polling
private extension CommonEthereumPendingTransactionsManager {
    func updatePendingTransactionsStatus() {
        guard pendingTransactionsCheckTask == nil else { return }

        pendingTransactionsCheckTask = Task { [weak self, walletAddress] in
            defer { self?.pendingTransactionsCheckTask = nil }

            while self?.pendingTransactionsSubject.value.isEmpty == false {
                do {
                    try await self?.syncPendingTransactions()
                } catch is CancellationError {
                    break
                } catch {
                    BSDKLogger.debug(
                        "Failed to sync pending Ethereum transactions for \(walletAddress): \(error)"
                    )
                }
                do {
                    try await Task.sleep(for: .seconds(Constants.transactionCheckInterval))
                } catch is CancellationError {
                    break
                } catch {
                    BSDKLogger.debug("Pending Ethereum transactions polling sleep interrupted: \(error)")
                }
            }
        }
    }
}

private extension CommonEthereumPendingTransactionsManager {
    enum Constants {
        static let pendingTransactionsStorageKey = "pendingTransactionsStorageKey"
        static let transactionExecutionTimeout: TimeInterval = 300 // 5 minutes
        static let transactionCheckInterval = 10
    }
}

private actor NetworkServiceCache {
    private var cache: [NetworkProviderType: EthereumNetworkService] = [:]

    func get(_ key: NetworkProviderType) -> EthereumNetworkService? {
        cache[key]
    }

    func set(_ service: EthereumNetworkService, for key: NetworkProviderType) {
        cache[key] = service
    }
}
