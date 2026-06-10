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
    }
}

// MARK: - AddressBookManager

extension CommonAddressBookManager: AddressBookManager {
    nonisolated var addressBookPublisher: AnyPublisher<AddressBook, Never> {
        repository.addressBookPublisher
    }

    func save(contact: AddressBookContact) async throws {
        var addressBook = try await repository.load()

        if let index = addressBook.firstIndex(where: { $0.id == contact.id }) {
            addressBook[index] = contact
        } else {
            addressBook.append(contact)
        }

        try await repository.save(addressBook: addressBook)
    }

    func remove(contact: AddressBookContact) async throws {
        var addressBook = try await repository.load()
        addressBook.removeAll { $0.id == contact.id }
        try await repository.save(addressBook: addressBook)
    }
}
