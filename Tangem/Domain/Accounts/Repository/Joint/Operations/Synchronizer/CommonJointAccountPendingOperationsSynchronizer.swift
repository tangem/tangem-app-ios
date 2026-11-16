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
    nonisolated let pendingOperationsPublisher: AnyPublisher<[JointAccountOperations], Never>

    private nonisolated let persistentStorage: JointAccountsPendingOperationsPersistentStorage
    private nonisolated let safeAddressResolver: JointAccountSafeAddressResolver
    private nonisolated let reader: JointAccountPendingOperationsReader
    private nonisolated let storageReadingQueue: DispatchQueue
    private let merger: JointAccountPendingOperationsMerger

    private var version = 0
    private var localUpdates: [LocalUpdate] = []

    init(
        persistentStorage: JointAccountsPendingOperationsPersistentStorage,
        safeAddressResolver: JointAccountSafeAddressResolver,
        merger: JointAccountPendingOperationsMerger = JointAccountPendingOperationsMerger()
    ) {
        let reader = JointAccountPendingOperationsReader(persistentStorage: persistentStorage, safeAddressResolver: safeAddressResolver)
        let storageReadingQueue = DispatchQueue(
            label: "com.tangem.CommonJointAccountPendingOperationsSynchronizer.storageReadingQueue",
            qos: .userInitiated
        )

        self.persistentStorage = persistentStorage
        self.safeAddressResolver = safeAddressResolver
        self.reader = reader
        self.storageReadingQueue = storageReadingQueue
        self.merger = merger

        pendingOperationsPublisher = persistentStorage
            .didUpdatePublisher
            .merge(with: safeAddressResolver.didUpdatePublisher)
            .prepend(()) // An initial value to trigger loading from storage
            .subscribe(on: storageReadingQueue)
            .receive(on: storageReadingQueue)
            .map { _ in reader.reload() }
            .removeDuplicates()
            .receiveOnMain()
            .share(replay: 1)
            .eraseToAnyPublisher()
    }
}

// MARK: - JointAccountPendingOperationsSynchronizer protocol conformance

extension CommonJointAccountPendingOperationsSynchronizer: JointAccountPendingOperationsSynchronizer {
    nonisolated var pendingOperations: [JointAccountOperations] {
        reader.pendingOperations
    }

    nonisolated func operationPublisher(id: String) -> AnyPublisher<JointAccountOperation?, Never> {
        persistentStorage
            .didUpdatePublisher
            .prepend(())
            .subscribe(on: storageReadingQueue)
            .receive(on: storageReadingQueue)
            .map { [reader] _ in reader.operation(id: id) }
            .removeDuplicates()
            .receiveOnMain()
            .eraseToAnyPublisher()
    }

    var checkpoint: JointAccountPendingOperationsCheckpoint {
        JointAccountPendingOperationsCheckpoint(version: version)
    }

    func apply(_ update: JointAccountPendingOperationsUpdate) async throws {
        version += 1
        localUpdates.append(LocalUpdate(version: version, update: update))

        try write(operationIds: [update.operationId]) { stored in
            merger.merge(stored, applying: update)
        }
    }

    func apply(
        refreshedOperation operation: JointAccountOperation,
        forCryptoAccountId cryptoAccountId: String,
        requestedAt checkpoint: JointAccountPendingOperationsCheckpoint
    ) async throws {
        let refresh = JointAccountPendingOperationsUpdate.operationRefreshed(operation, cryptoAccountId: cryptoAccountId)
        let unseenUpdates = localUpdates.filter { $0.version > checkpoint.version }.map(\.update)
        let operationIds = ([refresh] + unseenUpdates).map(\.operationId).toSet()

        try write(operationIds: operationIds) { stored in
            let refreshed = merger.merge(stored, applying: refresh)
            return unseenUpdates.reduce(refreshed) { merger.merge($0, applying: $1) }
        }
    }

    func apply(listing: [JointAccountOperations], requestedAt checkpoint: JointAccountPendingOperationsCheckpoint) async throws {
        let unseenUpdates = localUpdates.filter { $0.version > checkpoint.version }
        let replayedUpdates = unseenUpdates.map(\.update)
        let listedOperationIds = listing.flatMap { $0.operations.map(\.id) }
        let operationIds = (listedOperationIds + replayedUpdates.map(\.operationId)).toSet()

        try write(operationIds: operationIds) { stored in
            merger.merge(listing: listing, into: stored, replaying: replayedUpdates)
        }

        localUpdates = unseenUpdates
    }
}

// MARK: - Private

private extension CommonJointAccountPendingOperationsSynchronizer {
    func write(
        operationIds: Set<String>,
        merge: ([JointAccountOperations]) -> [JointAccountOperations]
    ) throws {
        let directory = JointAccountSafeDirectory(safeAddressResolver.accountSafes)

        try persistentStorage.update(operationIds: operationIds, safeAddresses: directory.safeAddresses) { storedItems in
            let trustedItems = directory.trustedItems(storedItems)
            let merged = merge(directory.records(from: trustedItems))
            return changes(in: merged, comparedTo: trustedItems, directory: directory)
        }

        reader.reload()
    }

    func changes(
        in merged: [JointAccountOperations],
        comparedTo storedItems: [JointOperationHistoryItem],
        directory: JointAccountSafeDirectory
    ) -> JointAccountsPendingOperationsChanges {
        let storedItemsKeyedByOperationIds = storedItems.keyedFirst(by: \.operation.id)
        let mergedOperationIds = merged.flatMap { $0.operations.map(\.id) }.toSet()

        let savedItems = merged.flatMap { record in
            record.operations.compactMap { operation in
                historyItem(
                    for: operation,
                    cryptoAccountId: record.cryptoAccountId,
                    storedItem: storedItemsKeyedByOperationIds[operation.id],
                    directory: directory
                )
            }
        }

        let removedOperationIds = storedItemsKeyedByOperationIds.keys
            .filter { !mergedOperationIds.contains($0) }
            .sorted()

        return JointAccountsPendingOperationsChanges(savedItems: savedItems, removedOperationIds: removedOperationIds)
    }

    func historyItem(
        for operation: JointAccountOperation,
        cryptoAccountId: String,
        storedItem: JointOperationHistoryItem?,
        directory: JointAccountSafeDirectory
    ) -> JointOperationHistoryItem? {
        guard storedItem?.operation != operation else {
            return nil
        }

        guard let safeAddress = directory.safeAddress(forCryptoAccountId: cryptoAccountId) else {
            JointAccountsLogger.warning("Skipping a joint operation of an account with no active Safe")
            return nil
        }

        return JointOperationHistoryItem(
            operation: operation,
            cryptoAccountId: cryptoAccountId,
            safeAddress: safeAddress,
            createdAt: operation.createdAt,
            threshold: operation.threshold
        )
    }
}

// MARK: - Auxiliary types

private extension CommonJointAccountPendingOperationsSynchronizer {
    struct LocalUpdate {
        let version: Int
        let update: JointAccountPendingOperationsUpdate
    }
}
