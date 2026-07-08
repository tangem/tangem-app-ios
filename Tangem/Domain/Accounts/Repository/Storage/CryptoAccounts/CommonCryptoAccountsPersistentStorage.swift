//
//  CryptoAccountsPersistentStorage.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

final class CommonCryptoAccountsPersistentStorage {
    @Injected(\.persistentStorage) private var persistentStorage: PersistentStorageProtocol

    private let key: PersistentStorageKey
    private let workingQueue: DispatchQueue
    private var storageDidUpdateSubject: CryptoAccountsPersistentStorageController.StorageDidUpdateSubject?

    /// Warmed asynchronously right after init and kept in sync on every write.
    /// Used to speed up application startup.
    private let cache = OSAllocatedUnfairLock<Cache>(initialState: .notWarmedUp)

    init(storageIdentifier: String) {
        key = .accounts(cid: storageIdentifier)
        workingQueue = DispatchQueue(
            label: "com.tangem.CommonCryptoAccountsPersistentStorage.workingQueue_\(storageIdentifier)",
            attributes: .concurrent,
            target: .global(qos: .userInitiated)
        )

        warmUpCache()
    }

    /// Unsafe because it must be called from `workingQueue` only.
    private func unsafeFetchOptional() throws -> [StoredCryptoAccount]? {
        return try persistentStorage.value(for: key)
    }

    /// Unsafe because it must be called from `workingQueue` only.
    private func unsafeFetch() -> [StoredCryptoAccount] {
        return (try? unsafeFetchOptional()) ?? []
    }

    /// Unsafe because it must be called from `workingQueue` only. Fetches from disk and populates `cacheState`
    /// in one step, so `accounts` and `isMigrationNeeded` are always derived consistently from the same read.
    @discardableResult
    private func unsafeFetchAndCache() -> (accounts: [StoredCryptoAccount], isMigrationNeeded: Bool) {
        let fetchedAccounts: [StoredCryptoAccount]?
        do {
            fetchedAccounts = try unsafeFetchOptional()
        } catch {
            assertionFailure(
                "CommonCryptoAccountsPersistentStorage unable to query migration status due to error: \(error)"
            )
            fetchedAccounts = nil
        }

        let accounts = fetchedAccounts ?? []
        let isMigrationNeeded = fetchedAccounts == nil
        populateCache(accounts: accounts, isMigrationNeeded: isMigrationNeeded)
        return (accounts, isMigrationNeeded)
    }

    /// Unsafe because it must be called from `workingQueue` only.
    private func unsafeSave(_ items: [StoredCryptoAccount]) {
        do {
            try persistentStorage.store(value: items, for: key)
            populateCache(accounts: items, isMigrationNeeded: false)
            storageDidUpdateSubject?.send()
        } catch {
            assertionFailure("CommonCryptoAccountsPersistentStorage saving error: \(error)")
        }
    }

    private func warmUpCache() {
        workingQueue.async { [weak self] in
            self?.unsafeFetchAndCache()
        }
    }

    private func populateCache(accounts: [StoredCryptoAccount], isMigrationNeeded: Bool) {
        cache.withLock { $0 = .warmedUp(accounts: accounts, isMigrationNeeded: isMigrationNeeded) }
    }

    private func retrieveFromCache() -> (accounts: [StoredCryptoAccount], isMigrationNeeded: Bool)? {
        cache.withLock { state in
            guard case .warmedUp(let accounts, let isMigrationNeeded) = state else {
                return nil
            }
            return (accounts, isMigrationNeeded)
        }
    }
}

// MARK: - Auxiliary types

private extension CommonCryptoAccountsPersistentStorage {
    enum Cache {
        case notWarmedUp
        case warmedUp(accounts: [StoredCryptoAccount], isMigrationNeeded: Bool)
    }
}

// MARK: - CryptoAccountsPersistentStorage protocol conformance

extension CommonCryptoAccountsPersistentStorage: CryptoAccountsPersistentStorage {
    func getList() -> [StoredCryptoAccount] {
        if let cached = retrieveFromCache() {
            return cached.accounts
        }

        return workingQueue.sync {
            unsafeFetchAndCache().accounts
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
        if let cached = retrieveFromCache() {
            return cached.isMigrationNeeded
        }

        return workingQueue.sync {
            unsafeFetchAndCache().isMigrationNeeded
        }
    }

    func bind(to storageDidUpdateSubject: CryptoAccountsPersistentStorageController.StorageDidUpdateSubject) {
        self.storageDidUpdateSubject = storageDidUpdateSubject
    }
}
