//
//  CommonJointAccountsPendingOperationsPersistentStorage.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

final class CommonJointAccountsPendingOperationsPersistentStorage {
    @Injected(\.persistentStorage) private var persistentStorage: PersistentStorageProtocol

    private let key: PersistentStorageKey
    private let workingQueue: DispatchQueue
    private let didUpdateSubject = PassthroughSubject<Void, Never>()

    /// Warmed by the first read and kept in step with every write, so a reader does not wait for the disk.
    private let cache = OSAllocatedUnfairLock<[StoredJointAccountPendingOperations]?>(initialState: nil)

    init(storageIdentifier: String) {
        key = .jointAccountPendingOperations(cid: storageIdentifier)
        workingQueue = DispatchQueue(
            label: "com.tangem.CommonJointAccountsPendingOperationsPersistentStorage.workingQueue_\(storageIdentifier)",
            attributes: .concurrent,
            target: .global(qos: .userInitiated)
        )
    }

    /// - Warning: `workingQueue` only.
    private func unsafeFetch() -> [StoredJointAccountPendingOperations] {
        do {
            let stored: LossyArray<StoredJointAccountPendingOperations>? = try persistentStorage.value(for: key)
            return stored?.wrappedValue ?? []
        } catch {
            JointAccountsLogger.error("Unable to read the pending joint account operations of a wallet", error: error)
            return []
        }
    }

    /// - Warning: `workingQueue` only.
    private func unsafeFetchAndCache() -> [StoredJointAccountPendingOperations] {
        let records = unsafeFetch()
        cache.withLock { $0 = records }

        return records
    }

    /// - Warning: `workingQueue` only.
    private func unsafeSave(_ records: [StoredJointAccountPendingOperations]) throws {
        try persistentStorage.store(value: records, for: key)
        cache.withLock { $0 = records }
        didUpdateSubject.send()
    }
}

// MARK: - JointAccountsPendingOperationsPersistentStorage protocol conformance

extension CommonJointAccountsPendingOperationsPersistentStorage: JointAccountsPendingOperationsPersistentStorage {
    var didUpdatePublisher: AnyPublisher<Void, Never> {
        didUpdateSubject.eraseToAnyPublisher()
    }

    func getList() -> [StoredJointAccountPendingOperations] {
        if let cached = cache.withLock({ $0 }) {
            return cached
        }

        return workingQueue.sync {
            unsafeFetchAndCache()
        }
    }

    func replace(with records: [StoredJointAccountPendingOperations]) throws {
        try workingQueue.sync(flags: .barrier) {
            guard records != unsafeFetch() else {
                return
            }

            try unsafeSave(records)
        }
    }

    func appendNewOrUpdateExisting(_ operation: JointAccountOperation, forCryptoAccountId cryptoAccountId: String) throws {
        try edit(operationsForCryptoAccountId: cryptoAccountId) { operations in
            // Updated in place, so that the order the listing reported survives an answer to one of them
            if let index = operations.firstIndex(where: { $0.id == operation.id }) {
                operations[index] = operation
            } else {
                operations.append(operation)
            }
        }
    }

    func remove(operationWithId operationId: String, forCryptoAccountId cryptoAccountId: String) throws {
        try edit(operationsForCryptoAccountId: cryptoAccountId) { operations in
            operations.removeAll { $0.id == operationId }
        }
    }
}

// MARK: - Private

private extension CommonJointAccountsPendingOperationsPersistentStorage {
    /// - Note: An account left with no operations keeps no record, the way a listing reporting none writes none.
    func edit(operationsForCryptoAccountId cryptoAccountId: String, _ edit: (inout [JointAccountOperation]) -> Void) throws {
        try workingQueue.sync(flags: .barrier) {
            let currentRecords = unsafeFetch()
            let index = currentRecords.firstIndex(by: cryptoAccountId)

            var operations = index.map { currentRecords[$0].operations } ?? []
            edit(&operations)

            var editedRecords = currentRecords

            switch (index, operations.isEmpty) {
            case (let index?, true):
                editedRecords.remove(at: index)
            case (let index?, false):
                editedRecords[index] = StoredJointAccountPendingOperations(cryptoAccountId: cryptoAccountId, operations: operations)
            case (nil, true):
                return
            case (nil, false):
                editedRecords.append(StoredJointAccountPendingOperations(cryptoAccountId: cryptoAccountId, operations: operations))
            }

            guard editedRecords != currentRecords else {
                return
            }

            try unsafeSave(editedRecords)
        }
    }
}
