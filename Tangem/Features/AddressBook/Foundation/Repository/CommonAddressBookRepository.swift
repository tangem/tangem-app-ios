//
//  CommonAddressBookRepository.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation

actor CommonAddressBookRepository {
    private let userWalletId: UserWalletId
    private let cryptographer: AddressBookCryptographer
    private let storage: AddressBookPersistentStorage
    private let eTagStorage: AddressBookETagStorage

    /// In-memory cache loaded once from disk, so reads don't hit the disk every time.
    private var cachedAddressBook: AddressBook?

    private nonisolated(unsafe) let addressBookSubject: CurrentValueSubject<AddressBook, Never>

    init(
        userWalletId: UserWalletId,
        cryptographer: AddressBookCryptographer,
        storage: AddressBookPersistentStorage,
        eTagStorage: AddressBookETagStorage
    ) {
        self.userWalletId = userWalletId
        self.cryptographer = cryptographer
        self.storage = storage
        self.eTagStorage = eTagStorage

        addressBookSubject = CurrentValueSubject(AddressBook(userWalletId: userWalletId, contacts: []))
    }

    /// Loads the address book once from disk and caches it.
    /// A file-level read error propagates; individual undecodable records are skipped.
    private func loaded() async throws -> AddressBook {
        if let cachedAddressBook {
            return cachedAddressBook
        }

        let encoded = try await storage.get()
        let decoded = try cryptographer.decode(addressBook: encoded)
        setCache(decoded)
        return decoded
    }

    private func setCache(_ addressBook: AddressBook) {
        cachedAddressBook = addressBook
        addressBookSubject.send(addressBook)
    }
}

// MARK: - AddressBookRepository protocol conformance

extension CommonAddressBookRepository: AddressBookRepository {
    nonisolated var addressBookPublisher: AnyPublisher<AddressBook, Never> {
        addressBookSubject
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    func load() async throws -> AddressBook {
        try await loaded()
    }

    func save(addressBook: AddressBook) async throws {
        let encoded = try cryptographer.encode(addressBook: addressBook)
        try await storage.save(addressBook: encoded)

        setCache(addressBook)
    }
}
