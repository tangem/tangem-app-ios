//
//  AddressBookPersistentStorage.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

protocol AddressBookPersistentStorage: Actor {
    func get() -> [String]
    func save(contacts: [String])
}

actor CommonAddressBookPersistentStorage {
    @Injected(\.persistentStorage) private var persistentStorage: PersistentStorageProtocol

    private let key: PersistentStorageKey = .addressBook
}

// MARK: - AddressBookPersistentStorage protocol conformance

extension CommonAddressBookPersistentStorage: AddressBookPersistentStorage {
    func get() -> [String] {
        do {
            return try persistentStorage.value(for: key) ?? []
        } catch {
            assertionFailure("CommonAddressBookPersistentStorage fetching error: \(error)")
            return []
        }
    }

    func save(contacts: [String]) {
        do {
            try persistentStorage.store(value: contacts, for: key)
        } catch {
            assertionFailure("CommonAddressBookPersistentStorage saving error: \(error)")
        }
    }
}
