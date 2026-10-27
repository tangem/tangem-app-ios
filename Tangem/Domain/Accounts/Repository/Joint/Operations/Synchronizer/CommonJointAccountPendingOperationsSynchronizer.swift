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
    private let merger: JointAccountPendingOperationsMerger

    private var version = 0
    private var localUpdates: [LocalUpdate] = []

    init(
        persistentStorage: JointAccountsPendingOperationsPersistentStorage,
        merger: JointAccountPendingOperationsMerger = JointAccountPendingOperationsMerger()
    ) {
        self.persistentStorage = persistentStorage
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

    func apply(_ update: JointAccountPendingOperationsUpdate) throws {
        version += 1
        localUpdates.append(LocalUpdate(version: version, update: update))

        let stored = persistentStorage.getList()
        try write(merger.merge(stored, applying: update), over: stored)
    }

    func apply(
        refreshedOperation operation: JointAccountOperation,
        forCryptoAccountId cryptoAccountId: String,
        requestedAt checkpoint: JointAccountPendingOperationsCheckpoint
    ) throws {
        let unseenUpdates = localUpdates.filter { $0.version > checkpoint.version }.map(\.update)

        let stored = persistentStorage.getList()
        let refreshed = merger.merge(stored, applying: .operationRefreshed(operation, cryptoAccountId: cryptoAccountId))
        try write(unseenUpdates.reduce(refreshed) { merger.merge($0, applying: $1) }, over: stored)
    }

    func apply(listing: [StoredJointAccountPendingOperations], requestedAt checkpoint: JointAccountPendingOperationsCheckpoint) throws {
        let unseenUpdates = localUpdates.filter { $0.version > checkpoint.version }

        let stored = persistentStorage.getList()
        try write(merger.merge(listing: listing, into: stored, replaying: unseenUpdates.map(\.update)), over: stored)

        localUpdates = unseenUpdates
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
}

// MARK: - Auxiliary types

private extension CommonJointAccountPendingOperationsSynchronizer {
    struct LocalUpdate {
        let version: Int
        let update: JointAccountPendingOperationsUpdate
    }
}
