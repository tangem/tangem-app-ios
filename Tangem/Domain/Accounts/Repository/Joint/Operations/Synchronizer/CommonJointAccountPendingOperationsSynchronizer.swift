//
//  CommonJointAccountPendingOperationsSynchronizer.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt
import TangemFoundation

actor CommonJointAccountPendingOperationsSynchronizer {
    /// - Note: `prepend` is used to emulate 'hot' publisher (observable) behavior.
    nonisolated let operationsPublisher: AnyPublisher<[StoredJointAccountPendingOperations], Never>

    private nonisolated let persistentStorage: JointAccountsPendingOperationsPersistentStorage
    private let historyEnricherFactory: TransactionHistoryJointAccountDataEnriching.Factory
    private let merger: JointAccountPendingOperationsMerger

    private var version = 0
    private var localUpdates: [LocalUpdate] = []

    init(
        persistentStorage: JointAccountsPendingOperationsPersistentStorage,
        historyEnricherFactory: @escaping TransactionHistoryJointAccountDataEnriching.Factory,
        merger: JointAccountPendingOperationsMerger = JointAccountPendingOperationsMerger()
    ) {
        self.persistentStorage = persistentStorage
        self.historyEnricherFactory = historyEnricherFactory
        self.merger = merger

        let storageReadingQueue = DispatchQueue(
            label: "com.tangem.CommonJointAccountPendingOperationsSynchronizer.storageReadingQueue",
            qos: .userInitiated
        )

        operationsPublisher = persistentStorage
            .didUpdatePublisher
            .prepend(()) // An initial value to trigger loading from storage
            .receive(on: storageReadingQueue)
            .map { _ in persistentStorage.getList() }
            .removeDuplicates()
            .receiveOnMain()
            .share(replay: 1)
            .eraseToAnyPublisher()
    }
}

// MARK: - JointAccountPendingOperationsSynchronizer protocol conformance

extension CommonJointAccountPendingOperationsSynchronizer: JointAccountPendingOperationsSynchronizer {
    nonisolated var operations: [StoredJointAccountPendingOperations] {
        persistentStorage.getList()
    }

    var checkpoint: JointAccountPendingOperationsCheckpoint {
        JointAccountPendingOperationsCheckpoint(version: version)
    }

    func apply(_ update: JointAccountPendingOperationsUpdate) async throws {
        version += 1
        localUpdates.append(LocalUpdate(version: version, update: update))

        let stored = persistentStorage.getList()
        let merged = merger.merge(stored, applying: update)
        try write(merged, over: stored)

        if case .operationRemoved(let operationId, _) = update {
            await historyEnricherFactory()?.removeOperations(withIds: [operationId])
        }

        await enrichHistory(with: changes(in: merged, comparedTo: stored))
    }

    func apply(
        refreshedOperation operation: JointAccountOperation,
        forCryptoAccountId cryptoAccountId: String,
        requestedAt checkpoint: JointAccountPendingOperationsCheckpoint
    ) async throws {
        let unseenUpdates = localUpdates.filter { $0.version > checkpoint.version }.map(\.update)

        let stored = persistentStorage.getList()
        let refreshed = merger.merge(stored, applying: .operationRefreshed(operation, cryptoAccountId: cryptoAccountId))
        let merged = unseenUpdates.reduce(refreshed) { merger.merge($0, applying: $1) }
        try write(merged, over: stored)

        await enrichHistory(with: changes(in: merged, comparedTo: stored))
    }

    func apply(listing: [StoredJointAccountPendingOperations], requestedAt checkpoint: JointAccountPendingOperationsCheckpoint) async throws {
        let unseenUpdates = localUpdates.filter { $0.version > checkpoint.version }

        let stored = persistentStorage.getList()
        let merged = merger.merge(listing: listing, into: stored, replaying: unseenUpdates.map(\.update))
        try write(merged, over: stored)

        localUpdates = unseenUpdates

        await enrichHistory(with: changes(in: merged, comparedTo: stored))
    }
}

// MARK: - Private

private extension CommonJointAccountPendingOperationsSynchronizer {
    func write(_ merged: [StoredJointAccountPendingOperations], over stored: [StoredJointAccountPendingOperations]) throws {
        guard merged != stored else {
            return
        }

        try persistentStorage.replace(with: merged)
    }

    func changes(
        in merged: [StoredJointAccountPendingOperations],
        comparedTo stored: [StoredJointAccountPendingOperations]
    ) -> [StoredJointAccountPendingOperations] {
        merged.compactMap { record in
            let storedOperations = stored.first(by: record.cryptoAccountId)?.operations ?? []
            let changedOperations = record.operations.filter { operation in
                storedOperations.first { $0.id == operation.id } != operation
            }

            guard changedOperations.isNotEmpty else {
                return nil
            }

            return StoredJointAccountPendingOperations(cryptoAccountId: record.cryptoAccountId, operations: changedOperations)
        }
    }

    func enrichHistory(with changes: [StoredJointAccountPendingOperations]) async {
        guard changes.isNotEmpty,
              let historyEnricher = await historyEnricherFactory() else {
            return
        }

        for record in changes {
            await historyEnricher.enrich(with: record.operations, cryptoAccountId: record.cryptoAccountId)
        }
    }
}

// MARK: - Auxiliary types

private extension CommonJointAccountPendingOperationsSynchronizer {
    struct LocalUpdate {
        let version: Int
        let update: JointAccountPendingOperationsUpdate
    }
}
