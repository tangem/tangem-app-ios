//
//  TransactionHistoryProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import CryptoSwift
import TangemExpress
import TangemFoundation

// [REDACTED_TODO_COMMENT]
final actor TransactionHistoryProvider {
    private let repository: TransactionHistoryRepository
    private let syncMetadataStorage: () async -> SyncMetadataStorage
    private let tokenItem: TokenItem
    private let userWalletId: UserWalletId
    private let address: String

    private nonisolated var maskedAddress: String {
        address.prefix(Constants.maskedAddressPrefixSuffixLength) + "••••" + address.suffix(Constants.maskedAddressPrefixSuffixLength)
    }

    private var stateValue: TransactionHistorySyncState = .idle(.waitingForInitial)
    private var subscribers = AsyncStream<TransactionHistorySyncState>.MulticastSubscribers<UUID>()

    private var inFlightInitialSyncTask: Task<Void, Never>?
    private var inFlightIncrementalSyncTask: Task<Void, Never>?

    private var _hasCompletedInitialSync: Bool?
    private var lastSuccessfulPullToRefreshAt: Date?

    init(
        repository: TransactionHistoryRepository,
        userWalletId: UserWalletId,
        tokenItem: TokenItem,
        address: String
    ) {
        self.repository = repository
        self.tokenItem = tokenItem
        self.userWalletId = userWalletId
        self.address = address

        syncMetadataStorage = { @MainActor in
            SyncMetadataStorage(userWalletId: userWalletId, address: address)
        }
    }

    private func emit(_ newState: TransactionHistorySyncState) {
        stateValue = newState
        subscribers.yield(newState)
    }

    private func markInitialSyncCompleted() {
        _hasCompletedInitialSync = true
        // Fire-and-forget, we don't need to await this because we have an actor-protected value
        runTask { [syncMetadataStorage] in
            let storage = await syncMetadataStorage()
            await MainActor.run { storage.hasCompletedInitialSync = true }
        }
    }

    private func hasCompletedInitialSync() async -> Bool {
        // Fast path, reading from an actor-protected value
        if let cached = _hasCompletedInitialSync {
            return cached
        }

        let value = await syncMetadataStorage().hasCompletedInitialSync

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

        let newSyncTask = runTask(in: self) { provider in
            await provider.performInitialSync()
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

        let newSyncTask = runTask(in: self) { provider in
            await provider.performDeltaSync()
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

        let newSyncTask = runTask(in: self) { provider in
            await provider.performUserInitiatedSync(kind: kind)
        }

        inFlightIncrementalSyncTask = newSyncTask
        await newSyncTask.value
    }
}

// MARK: - TransactionHistoryExpressDataEnriching protocol conformance

extension TransactionHistoryProvider: TransactionHistoryExpressDataEnriching {
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

extension TransactionHistoryProvider: Identifiable {
    nonisolated var id: String {
        userWalletId.stringValue + address
    }
}

// MARK: - TransactionHistoryProviding protocol conformance

extension TransactionHistoryProvider: TransactionHistoryProviding {}

// MARK: - CustomStringConvertible protocol conformance

extension TransactionHistoryProvider: CustomStringConvertible {
    nonisolated var description: String {
        objectDescription(
            self,
            userInfo: [
                "name": tokenItem.name,
                "type": tokenItem.isToken ? "Token" : "Coin",
                "derivation": tokenItem.blockchainNetwork.derivationPath?.rawPath ?? "nil",
                "address": maskedAddress,
            ]
        )
    }
}

// MARK: - Constants

private extension TransactionHistoryProvider {
    enum Constants {
        static let pullToRefreshThrottle: TimeInterval = 10
        static let postBroadcastDelay: Duration = .seconds(5)
        static let maskedAddressPrefixSuffixLength = 4
    }
}

// MARK: - Auxiliary types

private extension TransactionHistoryProvider {
    // [REDACTED_TODO_COMMENT]
    /// A dummy wrapper to allow initialization of a MainActor-isolated `AppStorageCompat` instance inside
    /// the synchronous and implicitly isolated init of the `TransactionHistoryProvider` actor.
    /// Without it, we either would have to make that init async or silence the compiler warning
    /// `Call to main actor-isolated initializer 'init...' in a synchronous actor-isolated context`.
    final class SyncMetadataStorage {
        @AppStorageCompat<SyncMetadataStorageKey, Bool>
        var hasCompletedInitialSync: Bool

        init(
            userWalletId: UserWalletId,
            address: String
        ) {
            _hasCompletedInitialSync = .init(wrappedValue: false, .makeKey(userWalletId: userWalletId, address: address))
        }
    }

    // [REDACTED_TODO_COMMENT]
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
