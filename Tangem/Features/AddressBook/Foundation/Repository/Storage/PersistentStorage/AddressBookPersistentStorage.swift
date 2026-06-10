//
//  AddressBookPersistentStorage.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

protocol AddressBookPersistentStorage: Actor {
    func get() throws -> [String]
    func save(contacts: [String]) throws
}

actor CommonAddressBookPersistentStorage {
    @Injected(\.persistentStorage) private var persistentStorage: PersistentStorageProtocol

    private let key: PersistentStorageKey

    init(storageIdentifier: String) {
        key = .addressBook(cid: storageIdentifier)
    }
}

// MARK: - AddressBookPersistentStorage protocol conformance

extension CommonAddressBookPersistentStorage: AddressBookPersistentStorage {
    func get() throws -> [String] {
        try persistentStorage.value(for: key) ?? []
    }

    func save(contacts: [String]) throws {
        try persistentStorage.store(value: contacts, for: key)
    }
}
