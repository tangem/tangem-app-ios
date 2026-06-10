//
//  CommonAddressBookPersistentStorage.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

actor CommonAddressBookPersistentStorage {
    @Injected(\.persistentStorage) private var persistentStorage: PersistentStorageProtocol

    private let key: PersistentStorageKey

    init(storageIdentifier: String) {
        key = .addressBook(cid: storageIdentifier)
    }
}

// MARK: - AddressBookPersistentStorage protocol conformance

extension CommonAddressBookPersistentStorage: AddressBookPersistentStorage {
    func get() throws -> Data {
        try persistentStorage.value(for: key) ?? Data()
    }

    func save(addressBook: Data) throws {
        try persistentStorage.store(value: addressBook, for: key)
    }
}
