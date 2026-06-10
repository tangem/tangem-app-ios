//
//  AddressBookRepository.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

protocol AddressBookRepository: Actor {
    nonisolated var addressBookPublisher: AnyPublisher<AddressBook, Never> { get }

    @discardableResult
    func load() async throws -> AddressBook

    func save(addressBook: AddressBook) async throws
}
