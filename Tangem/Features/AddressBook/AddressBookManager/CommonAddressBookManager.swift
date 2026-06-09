//
//  CommonAddressBookManager.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

actor CommonAddressBookManager {
    private let cryptographer: AddressBookСryptographer
    private let synchronizer: AddressBookAPISynchronizer
    private let storage: AddressBookPersistentStorage

    init(
        cryptographer: AddressBookСryptographer,
        synchronizer: AddressBookAPISynchronizer,
        storage: AddressBookPersistentStorage
    ) {
        self.cryptographer = cryptographer
        self.synchronizer = synchronizer
        self.storage = storage
    }

    private func loadContacts() async throws -> [AddressBookContact] {
        let encoded = await storage.get()
        return try encoded.compactMap { try cryptographer.decode(contact: $0) }
    }

    private func save(contacts: [AddressBookContact]) async throws {
        let encoded = try contacts.compactMap { try cryptographer.encode(contact: $0) }
        await storage.save(contacts: encoded)
    }
}

// MARK: - AddressBookManager

extension CommonAddressBookManager: AddressBookManager {
    var synchronizerState: AddressBookSynchronizerState {
        synchronizer.synchronizerState
    }

    func getAddresses() async throws -> [AddressBookContact] {
        try await loadContacts()
    }

    func save(contact: AddressBookContact) async throws {
        var contacts = try await loadContacts()

        if let index = contacts.firstIndex(of: contact) {
            contacts[index] = contact
        } else {
            contacts.append(contact)
        }

        try await save(contacts: contacts)
    }

    func remove(contact: AddressBookContact) async throws {
        var contacts = try await loadContacts()
        contacts.removeAll { $0 == contact }
        try await save(contacts: contacts)
    }
}
