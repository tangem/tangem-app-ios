//
//  CommonJointAccountsInvitesPersistentStorage.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

final class CommonJointAccountsInvitesPersistentStorage {
    @Injected(\.persistentStorage) private var persistentStorage: PersistentStorageProtocol

    private let key: PersistentStorageKey
    private let workingQueue: DispatchQueue
    private let didUpdateSubject = PassthroughSubject<Void, Never>()

    /// Warmed by the first read and kept in step with every write, so a reader does not wait for the disk.
    private let cache = OSAllocatedUnfairLock<[StoredJointAccountInvites]?>(initialState: nil)

    init(storageIdentifier: String) {
        key = .jointAccountInvites(cid: storageIdentifier)
        workingQueue = DispatchQueue(
            label: "com.tangem.CommonJointAccountsInvitesPersistentStorage.workingQueue_\(storageIdentifier)",
            attributes: .concurrent,
            target: .global(qos: .userInitiated)
        )
    }

    /// - Warning: `workingQueue` only.
    private func unsafeFetch() -> [StoredJointAccountInvites] {
        do {
            let stored: LossyArray<StoredJointAccountInvites>? = try persistentStorage.value(for: key)
            return stored?.wrappedValue ?? []
        } catch {
            JointAccountsLogger.error("Unable to read the joint account invites of a wallet", error: error)
            return []
        }
    }

    /// - Warning: `workingQueue` only.
    private func unsafeFetchAndCache() -> [StoredJointAccountInvites] {
        let records = unsafeFetch()
        cache.withLock { $0 = records }

        return records
    }

    /// - Warning: `workingQueue` only.
    private func unsafeSave(_ records: [StoredJointAccountInvites]) throws {
        try persistentStorage.store(value: records, for: key)
        cache.withLock { $0 = records }
        didUpdateSubject.send()
    }
}

// MARK: - JointAccountsInvitesPersistentStorage protocol conformance

extension CommonJointAccountsInvitesPersistentStorage: JointAccountsInvitesPersistentStorage {
    var didUpdatePublisher: AnyPublisher<Void, Never> {
        didUpdateSubject.eraseToAnyPublisher()
    }

    func getList() -> [StoredJointAccountInvites] {
        if let cached = cache.withLock({ $0 }) {
            return cached
        }

        return workingQueue.sync {
            unsafeFetchAndCache()
        }
    }

    func getInvites(forCryptoAccountId cryptoAccountId: String) -> [StoredJointAccountInvite]? {
        getList().first(by: cryptoAccountId)?.invites
    }

    func save(_ invites: [StoredJointAccountInvite], forCryptoAccountId cryptoAccountId: String) throws {
        // This combined read-write operation must be atomic, hence the barrier flag
        try workingQueue.sync(flags: .barrier) {
            let currentRecords = unsafeFetch()
            var editedRecords = currentRecords
            let record = StoredJointAccountInvites(cryptoAccountId: cryptoAccountId, invites: invites)

            // Updated in place, so that re-saving unchanged invites keeps the order and fails the dirty check
            if let index = editedRecords.firstIndex(by: cryptoAccountId) {
                editedRecords[index] = record
            } else {
                editedRecords.append(record)
            }

            guard editedRecords != currentRecords else {
                return
            }

            try unsafeSave(editedRecords)
        }
    }
}
