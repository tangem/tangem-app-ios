//
//  TransactionHistoryProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

final actor TransactionHistoryProvider {
    private static let pullToRefreshThrottle: TimeInterval = 10
    private static let postBroadcastDelayNanos: UInt64 = 5 * 1_000_000_000

    private let key: TransactionHistoryProviderKey

    private var stateValue: TransactionHistorySyncState = .idle(.waitingForInitial)
    private var subscribers: [UUID: AsyncStream<TransactionHistorySyncState>.Continuation] = [:]

    private var inFlightInitial: Task<Void, Never>?
    private var inFlightIncremental: Task<Void, Never>?

    private var hasCompletedInitial: Bool = false
    private var lastSuccessfulPullToRefreshAt: Date?

    init(key: TransactionHistoryProviderKey) {
        self.key = key
    }

    private func subscribe(id: UUID, continuation: AsyncStream<TransactionHistorySyncState>.Continuation) {
        subscribers[id] = continuation
        continuation.yield(stateValue)
    }

    private func unsubscribe(id: UUID) {
        subscribers.removeValue(forKey: id)
    }

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
                guard let self else { return }
                Task { await self.unsubscribe(id: subscriberId) }
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
        if let task = inFlightInitial {
            await task.value
            return
        }

        let task = Task { [weak self] in
            guard let self else { return }
            await performInitialSync()
        }
        inFlightInitial = task
        await task.value
        inFlightInitial = nil
    }

    func syncDelta() async {
        guard hasCompletedInitial else {
            return
        }

        if let task = inFlightInitial {
            await task.value
            return
        }
        if let task = inFlightIncremental {
            await task.value
            return
        }

        let task = Task { [weak self] in
            guard let self else { return }
            await performDeltaSync()
        }
        inFlightIncremental = task
        await task.value
        inFlightIncremental = nil
    }

    func syncUserInitiated(_ kind: UserInitiatedSyncKind) async {
        guard hasCompletedInitial else {
            return
        }

        if let task = inFlightInitial {
            await task.value
        }

        switch kind {
        case .pullToRefresh:
            if let last = lastSuccessfulPullToRefreshAt,
               Date().timeIntervalSince(last) < Self.pullToRefreshThrottle {
                return
            }
        case .postBroadcast:
            // Waiting for the transaction to be broadcasted into a mempool
            try? await Task.sleep(nanoseconds: Self.postBroadcastDelayNanos)
        }

        if let task = inFlightIncremental {
            await task.value
            return
        }

        let task = Task { [weak self] in
            guard let self else { return }
            await performUserInitiatedSync(kind: kind)
        }
        inFlightIncremental = task
        await task.value
        inFlightIncremental = nil

        if case .pullToRefresh = kind {
            lastSuccessfulPullToRefreshAt = Date()
        }
    }
}
