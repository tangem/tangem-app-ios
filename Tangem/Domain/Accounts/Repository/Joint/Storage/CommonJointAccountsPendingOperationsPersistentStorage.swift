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
}
