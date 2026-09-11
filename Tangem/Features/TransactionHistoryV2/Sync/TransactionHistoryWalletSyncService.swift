//
//  TransactionHistoryWalletSyncService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemExpress
import TangemFoundation

final actor TransactionHistoryWalletSyncService {
    nonisolated let mappingQueue = DispatchQueue(
        label: "com.tangem.TransactionHistoryWalletSyncService.mappingQueue",
        qos: .userInitiated,
        target: .global(qos: .userInitiated)
    )

    private let repository: TransactionHistoryRepository
    private let syncMetadataStorage: TransactionHistorySyncMetadataStorage
    private let userWalletId: UserWalletId

    private var stateValue: TransactionHistorySyncState = .idle(.neverSynced)
    private var subscribers = AsyncStream<TransactionHistorySyncState>.MulticastSubscribers<UUID>()

    private var inFlightInitialSyncTask: Task<Void, Never>?
    private var inFlightIncrementalSyncTask: Task<Void, Never>?

    private var _hasCompletedInitialSync: Bool?
    private var lastSuccessfulPullToRefreshAt: Date?

    init(
        repository: TransactionHistoryRepository,
        syncMetadataStorage: TransactionHistorySyncMetadataStorage,
        userWalletId: UserWalletId
    ) {
        self.repository = repository
        self.syncMetadataStorage = syncMetadataStorage
        self.userWalletId = userWalletId
    }

    private func emit(_ newState: TransactionHistorySyncState) {
        stateValue = newState
        subscribers.yield(newState)
    }

    private func markInitialSyncCompleted() {
        _hasCompletedInitialSync = true
        // Fire-and-forget, we don't need to await this because we have an actor-protected value
        runTask(in: self) { service in
            do {
                try await service.syncMetadataStorage.setIsInitialSyncDone(true)
            } catch {
                TransactionHistoryLogger.error(service, "Failed to persist the initial sync flag", error: error)
            }
        }
    }

    private func hasCompletedInitialSync() async -> Bool {
        // Fast path, reading from an actor-protected value
        if let cached = _hasCompletedInitialSync {
            return cached
        }

        let value: Bool

        do {
            value = try await syncMetadataStorage.isInitialSyncDone()
        } catch {
            // No caching on error, because we want to retry on the next call
            TransactionHistoryLogger.error(self, "Failed to read the initial sync flag", error: error)

            return false
        }

        // Double-check required since there is a suspension point above on storage read
        if let cached = _hasCompletedInitialSync {
            return cached
        }

        _hasCompletedInitialSync = value

        return value
    }

    private func performInitialSync() async {
        defer {
            inFlightInitialSyncTask = nil
        }

        emit(.syncing(.initial))

        do {
            try await repository.syncInitial()
            markInitialSyncCompleted()
            TransactionHistoryLogger.debug(self, "Initial sync finished")
            emit(.idle(.ready))
        } catch {
            // [REDACTED_TODO_COMMENT]
            TransactionHistoryLogger.error(self, "Initial sync failed", error: error)
            emit(.failed(.init(reason: .transport(message: error.localizedDescription), syncKind: .initial)))
        }
    }

    private func performDeltaSync() async {
        defer {
            inFlightIncrementalSyncTask = nil
        }

        emit(.syncing(.delta))

        do {
            try await repository.syncDelta()
            TransactionHistoryLogger.debug(self, "Delta sync finished")
            emit(.idle(.ready))
        } catch {
            // [REDACTED_TODO_COMMENT]
            TransactionHistoryLogger.error(self, "Delta sync failed", error: error)
            emit(.failed(.init(reason: .transport(message: error.localizedDescription), syncKind: .delta)))
        }
    }

    private func performUserInitiatedSync(kind: UserInitiatedSyncKind) async {
        defer {
            inFlightIncrementalSyncTask = nil
        }

        emit(.syncing(.userInitiated(kind)))

        do {
            try await repository.syncDelta()
            if case .pullToRefresh = kind {
                lastSuccessfulPullToRefreshAt = Date()
            }
            TransactionHistoryLogger.debug(self, "User-initiated sync finished: \(kind)")
            emit(.idle(.ready))
        } catch {
            // [REDACTED_TODO_COMMENT]
            TransactionHistoryLogger.error(self, "User-initiated sync failed: \(kind)", error: error)
            emit(.failed(.init(reason: .transport(message: error.localizedDescription), syncKind: .userInitiated(kind))))
        }
    }
}

// MARK: - TransactionHistorySyncing protocol conformance

extension TransactionHistoryWalletSyncService: TransactionHistorySyncing {
    var state: TransactionHistorySyncState {
        stateValue
    }

    nonisolated var stateUpdates: AsyncStream<TransactionHistorySyncState> {
        .multicast(
            with: self,
            onSubscribe: { service, id, continuation in
                service.subscribers.subscribe(id: id, continuation: continuation, currentValue: service.stateValue)
            },
            onUnsubscribe: { service, id in
                service.subscribers.unsubscribe(id: id)
            }
        )
    }

    func syncInitial() async {
        TransactionHistoryLogger.debug(self, "Initial sync requested")

        guard await !hasCompletedInitialSync() else {
            TransactionHistoryLogger.debug(self, "Skipping initial sync: already completed")
            return
        }

        if let inFlightSyncTask = inFlightInitialSyncTask {
            TransactionHistoryLogger.debug(self, "Joining in-flight initial sync")
            return await inFlightSyncTask.value
        }

        TransactionHistoryLogger.debug(self, "Starting initial sync")

        let newSyncTask = runTask(in: self) { service in
            await service.performInitialSync()
        }

        inFlightInitialSyncTask = newSyncTask
        await newSyncTask.value
    }

    func syncDelta() async {
        TransactionHistoryLogger.debug(self, "Delta sync requested")

        guard await hasCompletedInitialSync() else {
            TransactionHistoryLogger.debug(self, "Skipping delta sync: initial sync not completed yet")
            return
        }

        if let inFlightSyncTask = inFlightIncrementalSyncTask {
            TransactionHistoryLogger.debug(self, "Joining in-flight sync")
            return await inFlightSyncTask.value
        }

        TransactionHistoryLogger.debug(self, "Starting delta sync")

        let newSyncTask = runTask(in: self) { service in
            await service.performDeltaSync()
        }

        inFlightIncrementalSyncTask = newSyncTask
        await newSyncTask.value
    }

    func syncUserInitiated(_ kind: UserInitiatedSyncKind) async {
        TransactionHistoryLogger.debug(self, "User-initiated sync requested: \(kind)")

        guard await hasCompletedInitialSync() else {
            TransactionHistoryLogger.debug(self, "Skipping user-initiated sync: initial sync not completed yet")
            return
        }

        switch kind {
        case .pullToRefresh:
            if let last = lastSuccessfulPullToRefreshAt, Date().timeIntervalSince(last) < Constants.pullToRefreshThrottle {
                TransactionHistoryLogger.debug(self, "Skipping pull-to-refresh: throttled")
                return
            }
        case .postBroadcast:
            // Waiting for the transaction to be broadcasted into a mempool
            TransactionHistoryLogger.debug(self, "Delaying post-broadcast sync by \(Constants.postBroadcastDelay)")
            try? await Task.sleep(for: Constants.postBroadcastDelay)
        }

        if let inFlightSyncTask = inFlightIncrementalSyncTask {
            TransactionHistoryLogger.debug(self, "Joining in-flight sync")
            return await inFlightSyncTask.value
        }

        TransactionHistoryLogger.debug(self, "Starting user-initiated sync: \(kind)")

        let newSyncTask = runTask(in: self) { service in
            await service.performUserInitiatedSync(kind: kind)
        }

        inFlightIncrementalSyncTask = newSyncTask
        await newSyncTask.value
    }
}

// MARK: - TransactionHistoryExpressDataEnriching protocol conformance

extension TransactionHistoryWalletSyncService: TransactionHistoryExpressDataEnriching {
    func enrich(with transaction: SentSwapTransactionData) async {
        let exchangeTransaction = SentExpressTransactionHistoryMapper.mapToExchangeTransaction(transaction)
        await enrich(with: exchangeTransaction)
    }

    func enrich(with transaction: SentOnrampTransactionData) async {
        let onrampTransaction = SentExpressTransactionHistoryMapper.mapToOnrampTransaction(transaction)
        await enrich(with: onrampTransaction)
    }

    func enrich(with transaction: ExchangeTransaction) async {
        do {
            try await repository.add(transaction)
            TransactionHistoryLogger.debug(self, "Enriched with swap transaction: \(transaction.txId)")
        } catch {
            TransactionHistoryLogger.error(self, "Failed to enrich with swap transaction", error: error)
        }
    }

    func enrich(with transaction: OnrampTransaction) async {
        do {
            try await repository.add(transaction)
            TransactionHistoryLogger.debug(self, "Enriched with onramp transaction: \(transaction.txId)")
        } catch {
            TransactionHistoryLogger.error(self, "Failed to enrich with onramp transaction", error: error)
        }
    }
}

// MARK: - Identifiable protocol conformance

extension TransactionHistoryWalletSyncService: Identifiable {
    nonisolated var id: String {
        userWalletId.stringValue
    }
}

// MARK: - TransactionHistoryProviding protocol conformance

extension TransactionHistoryWalletSyncService: TransactionHistoryProviding {
    nonisolated func historyUpdates(
        for walletModelId: WalletModelId,
        walletModelAddressesPublisher: some Publisher<[String], Never>
    ) -> AsyncStream<[TransactionHistoryRecordsReader.Record]> {
        repository.historyUpdates(for: walletModelId, walletModelAddressesPublisher: walletModelAddressesPublisher)
    }
}

// MARK: - CustomStringConvertible protocol conformance

extension TransactionHistoryWalletSyncService: CustomStringConvertible {
    nonisolated var description: String {
        objectDescription(self, userInfo: ["userWalletId": userWalletId.stringValue])
    }
}

// MARK: - Constants

private extension TransactionHistoryWalletSyncService {
    enum Constants {
        static let pullToRefreshThrottle: TimeInterval = 10
        static let postBroadcastDelay: Duration = .seconds(5)
    }
}
