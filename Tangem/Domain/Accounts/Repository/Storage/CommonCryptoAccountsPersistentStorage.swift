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
    private var storageDidUpdateSubject: CryptoAccountsPersistentStorage.StorageDidUpdateSubject?

    init(storageIdentifier: String) {
        key = .accounts(cid: storageIdentifier)
        workingQueue = DispatchQueue(
            label: "com.tangem.CommonCryptoAccountsPersistentStorage.workingQueue_\(storageIdentifier)",
            attributes: .concurrent,
            target: .global(qos: .userInitiated)
        )
    }

    /// Unsafe because it must be called from `workingQueue` only.
    private func unsafeFetch() -> [StoredCryptoAccount] {
        return (try? persistentStorage.value(for: key)) ?? []
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
    func bind(to storageDidUpdateSubject: CryptoAccountsPersistentStorage.StorageDidUpdateSubject) {
        self.storageDidUpdateSubject = storageDidUpdateSubject
    }

    func getList() -> [StoredCryptoAccount] {
        workingQueue.sync {
            return unsafeFetch()
        }
    }

    func appendNewOrUpdateExisting(account: StoredCryptoAccount) {
        workingQueue.async(flags: .barrier) {
            var editedItems = self.unsafeFetch()
            var isDirty = false

            if let targetIndex = editedItems.firstIndex(where: { $0.derivationIndex == account.derivationIndex }) {
                isDirty = editedItems[targetIndex] != account
                editedItems[targetIndex] = account
            } else {
                isDirty = true
                editedItems.append(account)
            }

            if isDirty {
                self.unsafeSave(editedItems)
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

// MARK: - _CryptoAccountsPersistentStorage protocol conformance

extension CommonCryptoAccountsPersistentStorage: _CryptoAccountsPersistentStorage {
    func isMigrationNeeded() -> Bool {
        return workingQueue.sync {
            do {
                let accounts: [StoredCryptoAccount]? = try persistentStorage.value(for: key)
                return accounts != nil
            } catch {
                assertionFailure("CommonCryptoAccountsPersistentStorage unable to query migration status due to error: \(error)")
                return false
            }
        }
    }

    func bind(to storageDidUpdateSubject: StorageDidUpdateSubject) {
        self.storageDidUpdateSubject = storageDidUpdateSubject
    }
}
