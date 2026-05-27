//
//  TransactionHistoryProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

// [REDACTED_TODO_COMMENT]
final actor TransactionHistoryProvider {
    private var stateValue: TransactionHistorySyncState = .idle(.waitingForInitial)
    private var subscribers = AsyncStream<TransactionHistorySyncState>.Subscribers<UUID>()

    private var inFlightInitialSyncTask: Task<Void, Never>?
    private var inFlightIncrementalSyncTask: Task<Void, Never>?

    private var hasCompletedInitialSync: Bool = false
    private var lastSuccessfulPullToRefreshAt: Date?

    private func emit(_ newState: TransactionHistorySyncState) {
        stateValue = newState
        subscribers.yield(newState)
    }

    private func performInitialSync() async {
        // [REDACTED_TODO_COMMENT]
        emit(.syncing(.initial))
        hasCompletedInitialSync = true
        emit(.idle(.ready))
    }

    private func performDeltaSync() async {
        // [REDACTED_TODO_COMMENT]
        emit(.syncing(.delta))
        emit(.idle(.ready))
    }

    private func performUserInitiatedSync(kind: UserInitiatedSyncKind) async {
        // [REDACTED_TODO_COMMENT]
        emit(.syncing(.userInitiated(kind)))
        emit(.idle(.ready))
    }
}

// MARK: - TransactionHistorySyncing protocol conformance

extension TransactionHistoryProvider: TransactionHistorySyncing {
    var state: TransactionHistorySyncState {
        stateValue
    }

    nonisolated var stateUpdates: AsyncStream<TransactionHistorySyncState> {
        .multicast(
            with: self,
            onSubscribe: { provider, id, continuation in
                provider.subscribers.subscribe(id: id, continuation: continuation, currentValue: provider.stateValue)
            },
            onUnsubscribe: { provider, id in
                provider.subscribers.unsubscribe(id: id)
            }
        )
    }

    func syncInitial() async {
        if let inFlightSyncTask = inFlightInitialSyncTask {
            return await inFlightSyncTask.value
        }

        let newSyncTask = runTask(in: self) { provider in
            await provider.performInitialSync()
        }

        inFlightInitialSyncTask = newSyncTask
        await newSyncTask.value
        inFlightInitialSyncTask = nil
    }

    func syncDelta() async {
        guard hasCompletedInitialSync else {
            return
        }

        if let inFlightSyncTask = inFlightInitialSyncTask ?? inFlightIncrementalSyncTask {
            return await inFlightSyncTask.value
        }

        let newSyncTask = runTask(in: self) { provider in
            await provider.performDeltaSync()
        }

        inFlightIncrementalSyncTask = newSyncTask
        await newSyncTask.value
        inFlightIncrementalSyncTask = nil
    }

    func syncUserInitiated(_ kind: UserInitiatedSyncKind) async {
        guard hasCompletedInitialSync else {
            return
        }

        switch kind {
        case .pullToRefresh:
            if let last = lastSuccessfulPullToRefreshAt, Date().timeIntervalSince(last) < Constants.pullToRefreshThrottle {
                return
            }
        case .postBroadcast:
            // Waiting for the transaction to be broadcasted into a mempool
            try? await Task.sleep(for: Constants.postBroadcastDelay)
        }

        if let inFlightSyncTask = inFlightIncrementalSyncTask {
            return await inFlightSyncTask.value
        }

        let newSyncTask = runTask(in: self) { provider in
            await provider.performUserInitiatedSync(kind: kind)
        }

        inFlightIncrementalSyncTask = newSyncTask
        await newSyncTask.value
        inFlightIncrementalSyncTask = nil

        if case .pullToRefresh = kind {
            lastSuccessfulPullToRefreshAt = Date()
        }
    }
}

// MARK: - Constants

private extension TransactionHistoryProvider {
    enum Constants {
        static let pullToRefreshThrottle: TimeInterval = 10
        static let postBroadcastDelay: Duration = .seconds(5)
    }
}
