//
//  CommonTransactionHistoryRecordsStorage.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import GRDB
import TangemExpress
import TangemFoundation
import TangemAppDatabase

actor CommonTransactionHistoryRecordsStorage {
    @Injected(\.appDatabase) private var appDatabase: AppDatabase

    private var observationsKeyedByCurrency: [ExpressCurrency: DatabaseObservation] = [:]
    private let ownerAddress: String

    init(ownerAddress: String) {
        self.ownerAddress = ownerAddress
    }

    private func makeOrGetCachedDatabaseObservation(
        for currency: ExpressCurrency,
        startingObservationIfNeeded: Bool
    ) -> DatabaseObservation {
        let observation = observationsKeyedByCurrency[currency] ?? DatabaseObservation()
        observationsKeyedByCurrency[currency] = observation

        if startingObservationIfNeeded, observation.subscription == nil {
            observation.subscription = makeDatabaseObservationSubscription(for: currency)
        }

        return observation
    }

    private func makeDatabaseObservationSubscription(for currency: ExpressCurrency) -> AnyCancellable {
        let network = currency.network
        let address = TransactionHistoryAddressNormalizer.normalize(ownerAddress, networkID: network)
        let contractAddress = TransactionHistoryAddressNormalizer.normalize(currency.contractAddress, networkID: network)

        // Bare `Task` is used here intentionally to avoid capturing `self` strongly for the duration of the subscription
        return Task { [weak self] in
            let observation = ValueObservation.tracking { database in
                try TransactionHistoryIndexInfoRecord
                    .query(address: address, network: network, contractAddress: contractAddress)
                    .fetchAll(database) // [REDACTED_TODO_COMMENT]
            }

            do {
                guard let databaseHandle = try await self?.appDatabase.databaseHandle else {
                    return
                }

                for try await infos in observation.values(in: databaseHandle) {
                    let records = TransactionHistoryRecordsMapper.mapToTransactionHistoryExpressExtraInfo(infos)
                    await self?.emit(records, for: currency)
                }
            } catch {
                TransactionHistoryLogger.error("Failed to observe transaction history records:", error: error)

                // Drop the failed observation (but keep its subscribers) to allow retrying it on the next subscription
                await self?.performIsolated { storage in
                    guard !Task.isCancelled else {
                        return
                    }

                    storage.observationsKeyedByCurrency[currency]?.subscription = nil
                }
            }
        }.eraseToAnyCancellable()
    }

    private func emit(_ records: [TransactionHistoryRecordsStorage.Record], for currency: ExpressCurrency) {
        guard let observation = observationsKeyedByCurrency[currency], observation.snapshot != records else {
            return
        }

        observation.snapshot = records
        observation.subscribers.yield(records)
    }

    private func save(
        transactionRecords: [some PersistableRecord],
        indexRecords: [some PersistableRecord]
    ) async throws {
        guard transactionRecords.isNotEmpty else {
            return
        }

        try await appDatabase.databaseHandle.write { database in
            for transactionRecord in transactionRecords {
                try transactionRecord.upsert(database)
            }

            for indexRecord in indexRecords {
                // No upsert needed for index records, just do not insert if the index record already exists
                try indexRecord.insert(database, onConflict: .ignore)
            }
        }
    }
}

// MARK: - TransactionHistoryRecordsStorage protocol conformance

extension CommonTransactionHistoryRecordsStorage: TransactionHistoryRecordsStorage {
    nonisolated func updates(for currency: ExpressCurrency) -> AsyncStream<[TransactionHistoryExpressExtraInfo]> {
        .multicast(
            with: self,
            onSubscribe: { storage, id, continuation in
                let observation = storage.makeOrGetCachedDatabaseObservation(for: currency, startingObservationIfNeeded: true)
                observation.subscribers.subscribe(
                    id: id,
                    continuation: continuation,
                    currentValue: observation.snapshot
                )
            },
            onUnsubscribe: { storage, id in
                // No observation is started here: an unsubscribe racing ahead of its subscribe only records the cancellation
                storage.makeOrGetCachedDatabaseObservation(for: currency, startingObservationIfNeeded: false)
                    .subscribers
                    .unsubscribe(id: id)
            }
        )
    }

    func save(_ transactions: [ExchangeTransaction]) async throws {
        let transactionRecords = transactions.map { transaction in
            TransactionHistoryRecordsMapper.mapToExpressExchangeTransactionRecord(transaction, ownerAddress: ownerAddress)
        }
        let indexRecords = transactions.flatMap { transaction in
            TransactionHistoryRecordsMapper.mapToTransactionHistoryIndexRecords(transaction)
        }

        try await save(transactionRecords: transactionRecords, indexRecords: indexRecords)
    }

    func save(_ transactions: [OnrampTransaction]) async throws {
        let transactionRecords = transactions.map { transaction in
            TransactionHistoryRecordsMapper.mapToExpressOnrampTransactionRecord(transaction, ownerAddress: ownerAddress)
        }
        let indexRecords = transactions.flatMap { transaction in
            TransactionHistoryRecordsMapper.mapToTransactionHistoryIndexRecords(transaction)
        }

        try await save(transactionRecords: transactionRecords, indexRecords: indexRecords)
    }

    func fetchNextPage() async throws {
        // [REDACTED_TODO_COMMENT]
    }

    func clear() async throws {
        // [REDACTED_TODO_COMMENT]
    }
}

// MARK: - Auxiliary types

private extension CommonTransactionHistoryRecordsStorage {
    /// An aggregated type containing all the necessary information to observe transaction history records for a given currency:
    /// the latest snapshot, the subscribers, and the underlying GRDB observation subscription.
    final class DatabaseObservation {
        var subscribers = AsyncStream<[TransactionHistoryRecordsStorage.Record]>.MulticastSubscribers<UUID>()
        var snapshot: [TransactionHistoryRecordsStorage.Record] = []
        var subscription: AnyCancellable?
    }
}
