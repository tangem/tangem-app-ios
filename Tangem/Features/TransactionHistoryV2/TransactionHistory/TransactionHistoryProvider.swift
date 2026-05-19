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

    /// - Note: Multiple subscribers support for `AsyncStream`-baked observable properties. Required until
    /// https://github.com/apple/swift-async-algorithms/blob/main/Evolution/0016-share.md is implemented.
    private var subscribers: [UUID: AsyncStream<TransactionHistorySyncState>.Continuation] = [:]

    private var inFlightInitialSyncTask: Task<Void, Never>?
    private var inFlightIncrementalSyncTask: Task<Void, Never>?

    private var hasCompletedInitial: Bool = false
    private var lastSuccessfulPullToRefreshAt: Date?

    /// - Note: Multiple subscribers support for `AsyncStream`-baked observable properties. Required until
    /// https://github.com/apple/swift-async-algorithms/blob/main/Evolution/0016-share.md is implemented.
    private func subscribe(id: UUID, continuation: AsyncStream<TransactionHistorySyncState>.Continuation) {
        subscribers[id] = continuation
        continuation.yield(stateValue)
    }

    /// - Note: Multiple subscribers support for `AsyncStream`-baked observable properties. Required until
    /// https://github.com/apple/swift-async-algorithms/blob/main/Evolution/0016-share.md is implemented.
    private func unsubscribe(id: UUID) {
        subscribers.removeValue(forKey: id)
    }

    /// - Note: Multiple subscribers support for `AsyncStream`-baked observable properties. Required until
    /// https://github.com/apple/swift-async-algorithms/blob/main/Evolution/0016-share.md is implemented.
    private func emit(_ newState: TransactionHistorySyncState) {
        stateValue = newState
        for continuation in subscribers.values {
            continuation.yield(newState)
        }
    }

    private func performInitialSync() async {
        // [REDACTED_TODO_COMMENT]
        emit(.syncing(.initial))
        hasCompletedInitial = true
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
        AsyncStream { continuation in
            let subscriberId = UUID()

            continuation.onTermination = { @Sendable [weak self] _ in
                guard let self else {
                    return
                }

                Task {
                    await self.unsubscribe(id: subscriberId)
                }
            }

            Task { [weak self] in
                guard let self else {
                    continuation.finish()
                    return
                }

                await subscribe(id: subscriberId, continuation: continuation)
            }
        }
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
        guard hasCompletedInitial else {
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
        guard hasCompletedInitial else {
            return
        }

        if let inFlightSyncTask = inFlightInitialSyncTask {
            return await inFlightSyncTask.value
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
