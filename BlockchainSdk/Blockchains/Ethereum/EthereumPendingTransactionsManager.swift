//
//  EthereumPendingTransactionsManager.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol EthereumPendingTransactionsManager {
    var pendingTransactionsPublisher: AnyPublisher<[PendingTransactionRecord], Never> { get }

    func syncPendingTransactions() async throws

    func addTransaction(_ transaction: Transaction, hash: String)
}

final class CommonEthereumPendingTransactionsManager {
    private let walletAddress: String
    private let blockchain: Blockchain

    private let networkService: EthereumNetworkService
    private let dataStorage: BlockchainDataStorage
    private let mapper = PendingTransactionRecordMapper()
    private let addressConverter: EthereumAddressConverter

    private let pendingTransactionsSubject = CurrentValueSubject<[PendingTransactionRecord], Never>([])
    private var bag = Set<AnyCancellable>()

    init(
        walletAddress: String,
        blockchain: Blockchain,
        networkService: EthereumNetworkService,
        dataStorage: BlockchainDataStorage,
        addressConverter: EthereumAddressConverter
    ) {
        self.walletAddress = walletAddress
        self.blockchain = blockchain
        self.networkService = networkService
        self.dataStorage = dataStorage
        self.addressConverter = addressConverter

        let storedTransactions = getStoredTransactions()
        pendingTransactionsSubject.send(storedTransactions)

        bind()
    }
}

extension CommonEthereumPendingTransactionsManager: EthereumPendingTransactionsManager {
    var pendingTransactionsPublisher: AnyPublisher<[PendingTransactionRecord], Never> {
        pendingTransactionsSubject.eraseToAnyPublisher()
    }

    func syncPendingTransactions() async throws {
        let convertedAddress = try addressConverter.convertToETHAddress(walletAddress)

        let pendingTransactionsInfo = try await networkService.getPendingTransactionsInfo(
            address: convertedAddress,
            pendingTransactionHashes: pendingTransactionsSubject.value.filter { !$0.isDummy }.map(\.hash)
        ).async()

        // keep only those that are still pending.
        var pendingTransactions = pendingTransactionsSubject.value.filter { transaction in
            pendingTransactionsInfo.statuses[transaction.hash]?.isPending == true
        }

        let localPendingCount = pendingTransactions.count

        // detect unknown/external pending transactions (pendingTransactionCount - transactionsCount)
        let nodePendingCount = max(0, pendingTransactionsInfo.pendingTransactionCount - pendingTransactionsInfo.transactionCount)

        // add dummy pending records for unknown pending transactions
        if nodePendingCount > localPendingCount {
            let dummy = mapper.makeDummy(blockchain: blockchain)
            pendingTransactions.append(dummy)
        }

        pendingTransactionsSubject.send(pendingTransactions)
    }

    func addTransaction(_ transaction: Transaction, hash: String) {
        let pendingTransaction = mapper.mapToPendingTransactionRecord(transaction: transaction, hash: hash)

        var currentPendingTransactions = pendingTransactionsSubject.value
        currentPendingTransactions.append(pendingTransaction)

        pendingTransactionsSubject.send(currentPendingTransactions)
    }
}

private extension CommonEthereumPendingTransactionsManager {
    func bind() {
        pendingTransactionsPublisher
            .sink { [weak self] pendingTransactions in
                self?.store(transactions: pendingTransactions)
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
}

private extension CommonEthereumPendingTransactionsManager {
    enum Constants {
        static let pendingTransactionsStorageKey = "pendingTransactionsStorageKey"
    }
}
