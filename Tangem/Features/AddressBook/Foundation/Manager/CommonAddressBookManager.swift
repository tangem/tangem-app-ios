//
//  CommonAddressBookManager.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

/// The heart of address book management. For now it works purely against the local repository;
/// remote synchronization will be layered on top later.
actor CommonAddressBookManager {
    private let repository: AddressBookRepository

    init(repository: AddressBookRepository) {
        self.repository = repository

        Task { try? await repository.load() }
    }
}

// MARK: - AddressBookManager

extension CommonAddressBookManager: AddressBookManager {
    nonisolated var addressBookPublisher: AnyPublisher<AddressBook, Never> {
        repository.addressBookPublisher
    }

    func save(contact: AddressBookContact) async throws {
        let addressBook = try await repository.load()
        var contacts = addressBook.contacts

        if let index = contacts.firstIndex(where: { $0.id == contact.id }) {
            contacts[index] = contact
        } else {
            contacts.append(contact)
        }

        try await repository.save(addressBook: AddressBook(userWalletId: addressBook.userWalletId, contacts: contacts))
    }

    func remove(contact: AddressBookContact) async throws {
        let addressBook = try await repository.load()
        let contacts = addressBook.contacts.filter { $0.id != contact.id }
        try await repository.save(addressBook: AddressBook(userWalletId: addressBook.userWalletId, contacts: contacts))
    }
}
