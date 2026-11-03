//
//  JointOperationsHistorySyncService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress
import TangemFoundation

final actor JointOperationsHistorySyncService {
    private let networkService: JointOperationsHistoryNetworkService
    private let syncMetadataStorage: JointOperationsSyncMetadataStorage
    private let jointAccountsRepository: JointAccountsRepository

    private var stateValue: TransactionHistorySyncState = .idle(.neverSynced)
    private var subscribers = AsyncStream<TransactionHistorySyncState>.MulticastSubscribers<UUID>()

    private var inFlightInitialSyncTask: Task<Void, Never>?
    private var inFlightIncrementalSyncTask: Task<Void, Never>?

    private var _hasCompletedInitialSync: Bool?
    private var lastSuccessfulPullToRefreshAt: Date?

    init(
        networkService: JointOperationsHistoryNetworkService,
        syncMetadataStorage: JointOperationsSyncMetadataStorage,
        jointAccountsRepository: JointAccountsRepository
    ) {
        self.networkService = networkService
        self.syncMetadataStorage = syncMetadataStorage
        self.jointAccountsRepository = jointAccountsRepository
    }

    private var hasActiveJointAccounts: Bool {
        jointAccountsRepository.jointAccounts.contains { $0.status.isActive }
    }

    private func emit(_ newState: TransactionHistorySyncState) {
        stateValue = newState
        subscribers.yield(newState)
    }

    private func hasCompletedInitialSync() async -> Bool {
        if let cached = _hasCompletedInitialSync {
            return cached
        }

        let value: Bool

        do {
            value = try await syncMetadataStorage.isInitialSyncDone()
        } catch {
            TransactionHistoryLogger.error(self, "Failed to read the initial sync flag", error: error)
            return false
        }

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

        let previousState = stateValue
        emit(.syncing(.initial))

        do {
            try await networkService.syncInitial()
            _hasCompletedInitialSync = true
            TransactionHistoryLogger.debug(self, "Initial sync finished")
            emit(.idle(.ready))
        } catch is CancellationError {
            TransactionHistoryLogger.debug(self, "Initial sync cancelled")
            emit(previousState)
        } catch {
            TransactionHistoryLogger.error(self, "Initial sync failed", error: error)
            await handleFailure(error, syncKind: .initial)
        }
    }

    private func performIncrementalSync(kind: TransactionHistorySyncState.Kind) async {
        defer {
            inFlightIncrementalSyncTask = nil
        }

        let previousState = stateValue
        emit(.syncing(kind))

        do {
            try await networkService.syncDelta()
            if case .userInitiated(.pullToRefresh) = kind {
                lastSuccessfulPullToRefreshAt = Date()
            }
            TransactionHistoryLogger.debug(self, "Incremental sync finished: \(kind)")
            emit(.idle(.ready))
        } catch is CancellationError {
            TransactionHistoryLogger.debug(self, "Incremental sync cancelled: \(kind)")
            emit(previousState)
        } catch {
            TransactionHistoryLogger.error(self, "Incremental sync failed: \(kind)", error: error)
            await handleFailure(error, syncKind: kind)
        }
    }

    private func handleFailure(_ error: Error, syncKind: TransactionHistorySyncState.Kind) async {
        guard let apiError = error as? TangemAPIError, apiError.code == .badRequest else {
            emit(.failed(.init(reason: .transport(message: error.localizedDescription), syncKind: syncKind)))
            return
        }

        TransactionHistoryLogger.info(self, "The history refused the cursor; the sync starts over")

        do {
            try await syncMetadataStorage.clear()
            _hasCompletedInitialSync = false
        } catch {
            TransactionHistoryLogger.error(self, "Failed to reset the sync state", error: error)
            _hasCompletedInitialSync = nil
        }

        emit(.failed(.init(reason: .cursorReset, syncKind: syncKind)))
    }

    private func startIncrementalSync(kind: TransactionHistorySyncState.Kind) async {
        if let inFlightSyncTask = inFlightIncrementalSyncTask {
            TransactionHistoryLogger.debug(self, "Joining in-flight sync")
            return await inFlightSyncTask.value
        }

        TransactionHistoryLogger.debug(self, "Starting incremental sync: \(kind)")

        let newSyncTask = runTask(in: self) { service in
            await service.performIncrementalSync(kind: kind)
        }

        inFlightIncrementalSyncTask = newSyncTask
        await newSyncTask.value
    }
}

// MARK: - JointOperationsHistorySyncing protocol conformance

extension JointOperationsHistorySyncService: JointOperationsHistorySyncing {
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

        guard hasActiveJointAccounts else {
            TransactionHistoryLogger.debug(self, "Skipping initial sync: no active joint accounts")
            return
        }

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

        guard hasActiveJointAccounts else {
            TransactionHistoryLogger.debug(self, "Skipping delta sync: no active joint accounts")
            return
        }

        guard await hasCompletedInitialSync() else {
            TransactionHistoryLogger.debug(self, "Skipping delta sync: initial sync not completed yet")
            return
        }

        await startIncrementalSync(kind: .delta)
    }

    func syncUserInitiated(_ kind: UserInitiatedSyncKind) async {
        TransactionHistoryLogger.debug(self, "User-initiated sync requested: \(kind)")

        guard hasActiveJointAccounts else {
            TransactionHistoryLogger.debug(self, "Skipping user-initiated sync: no active joint accounts")
            return
        }

        guard await hasCompletedInitialSync() else {
            TransactionHistoryLogger.debug(self, "Skipping user-initiated sync: initial sync not completed yet")
            return
        }

        if case .pullToRefresh = kind,
           let last = lastSuccessfulPullToRefreshAt,
           Date().timeIntervalSince(last) < Constants.pullToRefreshThrottle {
            TransactionHistoryLogger.debug(self, "Skipping pull-to-refresh: throttled")
            return
        }

        await startIncrementalSync(kind: .userInitiated(kind))
    }
}

// MARK: - CustomStringConvertible protocol conformance

extension JointOperationsHistorySyncService: CustomStringConvertible {
    nonisolated var description: String {
        objectDescription(self)
    }
}

// MARK: - Constants

private extension JointOperationsHistorySyncService {
    enum Constants {
        static let pullToRefreshThrottle: TimeInterval = 10
    }
}
