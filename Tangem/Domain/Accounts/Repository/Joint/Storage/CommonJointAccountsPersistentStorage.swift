//
//  CommonJointAccountsPersistentStorage.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

final class CommonJointAccountsPersistentStorage {
    @Injected(\.persistentStorage) private var persistentStorage: PersistentStorageProtocol

    private let key: PersistentStorageKey
    private let workingQueue: DispatchQueue
    private let didUpdateSubject = PassthroughSubject<Void, Never>()

    /// Warmed by the first read and kept in step with every write, so a reader does not wait for the disk.
    private let cache = OSAllocatedUnfairLock<[StoredJointAccount]?>(initialState: nil)

    init(storageIdentifier: String) {
        key = .jointAccounts(cid: storageIdentifier)
        workingQueue = DispatchQueue(
            label: "com.tangem.CommonJointAccountsPersistentStorage.workingQueue_\(storageIdentifier)",
            attributes: .concurrent,
            target: .global(qos: .userInitiated)
        )
    }

    /// - Warning: `workingQueue` only.
    private func unsafeFetch() -> [StoredJointAccount] {
        do {
            let stored: LossyArray<StoredJointAccount>? = try persistentStorage.value(for: key)
            return stored?.wrappedValue ?? []
        } catch {
            JointAccountsLogger.error("Unable to read the joint accounts of a wallet", error: error)
            return []
        }
    }

    /// - Warning: `workingQueue` only.
    private func unsafeFetchAndCache() -> [StoredJointAccount] {
        let accounts = unsafeFetch()
        cache.withLock { $0 = accounts }

        return accounts
    }

    /// - Warning: `workingQueue` only.
    private func unsafeSave(_ accounts: [StoredJointAccount]) throws {
        try persistentStorage.store(value: accounts, for: key)
        cache.withLock { $0 = accounts }
        didUpdateSubject.send()
    }
}

// MARK: - JointAccountsPersistentStorage protocol conformance

extension CommonJointAccountsPersistentStorage: JointAccountsPersistentStorage {
    var didUpdatePublisher: AnyPublisher<Void, Never> {
        didUpdateSubject.eraseToAnyPublisher()
    }

    func getList() -> [StoredJointAccount] {
        if let cached = cache.withLock({ $0 }) {
            return cached
        }

        return workingQueue.sync {
            unsafeFetchAndCache()
        }
    }

    func appendNewOrUpdateExisting(_ account: StoredJointAccount) throws {
        // This combined read-write operation must be atomic, hence the barrier flag
        try workingQueue.sync(flags: .barrier) {
            let currentAccounts = unsafeFetch()
            var editedAccounts = currentAccounts

            // Updated in place, so that re-saving an unchanged account keeps the order and fails the dirty check
            if let index = editedAccounts.firstIndex(where: { $0.cryptoAccountId.caseInsensitiveEquals(to: account.cryptoAccountId) }) {
                editedAccounts[index] = account
            } else {
                editedAccounts.append(account)
            }

            guard editedAccounts != currentAccounts else {
                return
            }

            try unsafeSave(editedAccounts)
        }
    }

    func replace(with accounts: [StoredJointAccount]) throws {
        try workingQueue.sync(flags: .barrier) {
            guard accounts != unsafeFetch() else {
                return
            }

            try unsafeSave(accounts)
        }
    }
}
