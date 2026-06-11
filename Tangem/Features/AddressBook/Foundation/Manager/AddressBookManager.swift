//
//  AddressBookManager.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol AddressBookManager: Actor {
    nonisolated var addressBookPublisher: AnyPublisher<AddressBook, Never> { get }

    func save(contact: AddressBookContact) async throws
    func remove(contact: AddressBookContact) async throws
}
