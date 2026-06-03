//
//  TransactionHistoryProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import CryptoSwift
import TangemFoundation

// [REDACTED_TODO_COMMENT]
final actor TransactionHistoryProvider {
    private let repository: TransactionHistoryRepository
    private let syncMetadataStorage: () async -> SyncMetadataStorage

    private var stateValue: TransactionHistorySyncState = .idle(.waitingForInitial)
    private var subscribers = AsyncStream<TransactionHistorySyncState>.MulticastSubscribers<UUID>()

    private var inFlightInitialSyncTask: Task<Void, Never>?
    private var inFlightIncrementalSyncTask: Task<Void, Never>?

    private var lastSuccessfulPullToRefreshAt: Date?

    init(
        repository: TransactionHistoryRepository,
        userWalletId: UserWalletId,
        address: String
    ) {
        self.repository = repository
        syncMetadataStorage = { @MainActor in
            SyncMetadataStorage(userWalletId: userWalletId, address: address)
        }
    }

    private func emit(_ newState: TransactionHistorySyncState) {
        stateValue = newState
        subscribers.yield(newState)
    }

    private func performInitialSync() async {
        emit(.syncing(.initial))
        do {
            try await repository.syncInitial()
            let storage = await syncMetadataStorage() // Can't be fetched inside the synchronous `MainActor.run` call
            await MainActor.run { storage.hasCompletedInitialSync = true }
            emit(.idle(.ready))
        } catch {
            // [REDACTED_TODO_COMMENT]
            emit(.failed(.init(reason: .transport(message: error.localizedDescription), syncKind: .initial)))
        }
    }

    private func performDeltaSync() async {
        emit(.syncing(.delta))
        do {
            try await repository.syncDelta()
            emit(.idle(.ready))
        } catch {
            // [REDACTED_TODO_COMMENT]
            emit(.failed(.init(reason: .transport(message: error.localizedDescription), syncKind: .delta)))
        }
    }

    private func performUserInitiatedSync(kind: UserInitiatedSyncKind) async {
        emit(.syncing(.userInitiated(kind)))
        do {
            try await repository.syncDelta()
            emit(.idle(.ready))
        } catch {
            // [REDACTED_TODO_COMMENT]
            emit(.failed(.init(reason: .transport(message: error.localizedDescription), syncKind: .userInitiated(kind))))
        }
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
        guard await !syncMetadataStorage().hasCompletedInitialSync else {
            return
        }

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
        guard await syncMetadataStorage().hasCompletedInitialSync else {
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
        guard await syncMetadataStorage().hasCompletedInitialSync else {
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

// MARK: - Auxiliary types

private extension TransactionHistoryProvider {
    /// A dummy wrapper to allow initialization of a MainActor-isolated `AppStorageCompat` instance inside
    /// the synchronous and implicitly isolated init of the `TransactionHistoryProvider` actor.
    /// Without it, we either would have to make that init async or silence the compiler warning
    /// `Call to main actor-isolated initializer 'init...' in a synchronous actor-isolated context`.
    final class SyncMetadataStorage {
        @AppStorageCompat<SyncMetadataStorageKey, Bool>
        private(set) var hasCompletedInitialSync: Bool

        init(
            userWalletId: UserWalletId,
            address: String
        ) {
            _hasCompletedInitialSync = .init(wrappedValue: false, .makeKey(userWalletId: userWalletId, address: address))
        }
    }

    struct SyncMetadataStorageKey: RawRepresentable {
        let rawValue: String

        static func makeKey(
            userWalletId: UserWalletId,
            address: String
        ) -> Self {
            Self(rawValue: "TransactionHistoryV2InitialSyncCompleted_\(userWalletId.stringValue)_\(address.sha256())")
        }
    }
}
