//
//  CommonTransactionHistoryRecordsReader.swift
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

actor CommonTransactionHistoryRecordsReader {
    @Injected(\.appDatabase) private var appDatabase: AppDatabase

    private var observationsKeyedByWalletModel: [WalletModelId: DatabaseObservation] = [:]

    private func subscribe(
        id: UUID,
        continuation: AsyncStream<[TransactionHistoryRecordsReader.Record]>.Continuation,
        for walletModelId: WalletModelId,
        walletModelAddressesPublisher: some Publisher<[String], Never>
    ) {
        let observation = makeOrGetCachedDatabaseObservation(for: walletModelId)

        if observation.subscription == nil {
            observation.subscription = makeDatabaseObservationSubscription(
                for: walletModelId,
                walletModelAddressesPublisher: walletModelAddressesPublisher
            )
        }

        observation.subscribers.subscribe(id: id, continuation: continuation, currentValue: observation.snapshot)

        discardObservationIfIdle(for: walletModelId)
    }

    private func unsubscribe(id: UUID, for walletModelId: WalletModelId) {
        makeOrGetCachedDatabaseObservation(for: walletModelId).subscribers.unsubscribe(id: id)

        discardObservationIfIdle(for: walletModelId)
    }

    /// Releases the observation once nothing is subscribed to it any more, so that neither the address loop nor the
    /// database observation outlive their subscribers. It also means the next subscriber starts from scratch over
    /// its own addresses publisher instead of inheriting the one captured by whoever subscribed first — the two
    /// differ once a wallet model has been recreated.
    private func discardObservationIfIdle(for walletModelId: WalletModelId) {
        guard let observation = observationsKeyedByWalletModel[walletModelId], observation.subscribers.isEmpty else {
            return
        }

        observation.subscription?.cancel()
        observationsKeyedByWalletModel.removeValue(forKey: walletModelId)
    }

    private func makeOrGetCachedDatabaseObservation(for walletModelId: WalletModelId) -> DatabaseObservation {
        let observation = observationsKeyedByWalletModel[walletModelId] ?? DatabaseObservation()
        observationsKeyedByWalletModel[walletModelId] = observation

        return observation
    }

    private func makeDatabaseObservationSubscription(
        for walletModelId: WalletModelId,
        walletModelAddressesPublisher: some Publisher<[String], Never>
    ) -> AnyCancellable {
        // Bare `Task` is used here intentionally to avoid capturing `self` strongly for the duration of the subscription
        return Task { [weak self] in
            var observationTask: Task<Void, Never>?

            defer {
                observationTask?.cancel()
            }

            for await addresses in await walletModelAddressesPublisher.values_ {
                observationTask?.cancel()
                observationTask = Task { [weak self] in
                    await self?.observeRecords(for: walletModelId, addresses: addresses)
                }
            }
        }.eraseToAnyCancellable()
    }

    private func observeRecords(for walletModelId: WalletModelId, addresses: [String]) async {
        let currency = walletModelId.tokenItem.expressCurrency.asCurrency
        let network = currency.network
        let contractAddress = TransactionHistoryAddressNormalizer.normalize(currency.contractAddress, networkID: network)
        let normalizedAddresses = addresses.map { TransactionHistoryAddressNormalizer.normalize($0, networkID: network) }

        let observation = ValueObservation.tracking { database in
            try TransactionHistoryIndexInfoRecord
                .query(addresses: normalizedAddresses, network: network, contractAddress: contractAddress)
                .fetchAll(database) // [REDACTED_TODO_COMMENT]
        }

        do {
            for try await infos in observation.values(in: try appDatabase.databaseHandle) {
                let records = TransactionHistoryRecordsMapper.mapToTransactionHistoryExpressExtraInfo(infos)
                emit(records, for: walletModelId)
            }
        } catch {
            guard !Task.isCancelled else {
                return
            }

            TransactionHistoryLogger.error("Failed to observe transaction history records:", error: error)
            observationsKeyedByWalletModel[walletModelId]?.subscription = nil
        }
    }

    private func emit(_ records: [TransactionHistoryRecordsReader.Record], for walletModelId: WalletModelId) {
        guard let observation = observationsKeyedByWalletModel[walletModelId], observation.snapshot != records else {
            return
        }

        observation.snapshot = records
        observation.subscribers.yield(records)
    }
}

// MARK: - TransactionHistoryRecordsReader protocol conformance

extension CommonTransactionHistoryRecordsReader: TransactionHistoryRecordsReader {
    nonisolated func updates(
        for walletModelId: WalletModelId,
        walletModelAddressesPublisher: some Publisher<[String], Never>
    ) -> AsyncStream<[TransactionHistoryRecordsReader.Record]> {
        .multicast(
            with: self,
            onSubscribe: { reader, id, continuation in
                reader.subscribe(
                    id: id,
                    continuation: continuation,
                    for: walletModelId,
                    walletModelAddressesPublisher: walletModelAddressesPublisher
                )
            },
            onUnsubscribe: { reader, id in
                reader.unsubscribe(id: id, for: walletModelId)
            }
        )
    }

    func fetchNextPage() async throws {
        // [REDACTED_TODO_COMMENT]
    }
}

// MARK: - Auxiliary types

private extension CommonTransactionHistoryRecordsReader {
    /// An aggregated type containing all the necessary information to observe transaction history records for a given
    /// wallet model: the latest snapshot, the subscribers, and the underlying GRDB observation subscription.
    final class DatabaseObservation {
        var subscribers = AsyncStream<[TransactionHistoryRecordsReader.Record]>.MulticastSubscribers<UUID>()
        var snapshot: [TransactionHistoryRecordsReader.Record] = []
        var subscription: AnyCancellable?
    }
}
