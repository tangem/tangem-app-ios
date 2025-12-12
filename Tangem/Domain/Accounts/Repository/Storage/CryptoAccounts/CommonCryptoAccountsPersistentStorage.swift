//
//  CryptoAccountsPersistentStorage.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine

final class CommonCryptoAccountsPersistentStorage {
    @Injected(\.persistentStorage) private var persistentStorage: PersistentStorageProtocol

    private let key: PersistentStorageKey
    private let workingQueue: DispatchQueue
    private var storageDidUpdateSubject: CryptoAccountsPersistentStorageController.StorageDidUpdateSubject?

    init(storageIdentifier: String) {
        key = .accounts(cid: storageIdentifier)
        workingQueue = DispatchQueue(
            label: "com.tangem.CommonCryptoAccountsPersistentStorage.workingQueue_\(storageIdentifier)",
            attributes: .concurrent,
            target: .global(qos: .userInitiated)
        )
    }

    /// Unsafe because it must be called from `workingQueue` only.
    private func unsafeFetchOptional() throws -> [StoredCryptoAccount]? {
        return try persistentStorage.value(for: key)
    }

    /// Unsafe because it must be called from `workingQueue` only.
    private func unsafeFetch() -> [StoredCryptoAccount] {
        return (try? unsafeFetchOptional()) ?? []
    }

    /// Unsafe because it must be called from `workingQueue` only.
    private func unsafeSave(_ items: [StoredCryptoAccount]) {
        do {
            try persistentStorage.store(value: items, for: key)
            storageDidUpdateSubject?.send()
        } catch {
            assertionFailure("CommonCryptoAccountsPersistentStorage saving error: \(error)")
        }
    }
}

// MARK: - CryptoAccountsPersistentStorage protocol conformance

extension CommonCryptoAccountsPersistentStorage: CryptoAccountsPersistentStorage {
    func getList() -> [StoredCryptoAccount] {
        workingQueue.sync {
            return unsafeFetch()
        }
    }

    func appendNewOrUpdateExisting(_ accounts: [StoredCryptoAccount]) {
        workingQueue.async(flags: .barrier) {
            let currentItems = self.unsafeFetch()
            let merger = StoredCryptoAccountsMerger(preserveTokensWhileMergingAccounts: false)
            let (editedItems, isDirty) = merger.merge(oldAccounts: currentItems, newAccounts: accounts)

            if isDirty {
                self.unsafeSave(editedItems)
            }
        }
    }

    func replace(with accounts: [StoredCryptoAccount]) {
        workingQueue.async(flags: .barrier) {
            let currentItems = self.unsafeFetch()
            let isDirty = accounts != currentItems

            if isDirty {
                self.unsafeSave(accounts)
            }
        }
    }

    func removeAll(where shouldBeRemoved: @escaping (StoredCryptoAccount) -> Bool) {
        // This combined read-write operation must be atomic, hence the barrier flag
        workingQueue.async(flags: .barrier) {
            let currentItems = self.unsafeFetch()
            var editedItems = currentItems

            editedItems.removeAll(where: shouldBeRemoved)
            let isDirty = editedItems.count != currentItems.count

            if isDirty {
                self.unsafeSave(editedItems)
            }
        }
    }

    func removeAll() {
        workingQueue.async(flags: .barrier) {
            self.unsafeSave([])
        }
    }
}

// MARK: - CryptoAccountsPersistentStorageController protocol conformance

extension CommonCryptoAccountsPersistentStorage: CryptoAccountsPersistentStorageController {
    func isMigrationNeeded() -> Bool {
        return workingQueue.sync {
            do {
                return try unsafeFetchOptional() == nil
            } catch {
                assertionFailure("CommonCryptoAccountsPersistentStorage unable to query migration status due to error: \(error)")
                return true
            }
        }
    }

    func bind(to storageDidUpdateSubject: CryptoAccountsPersistentStorageController.StorageDidUpdateSubject) {
        self.storageDidUpdateSubject = storageDidUpdateSubject
    }
}
