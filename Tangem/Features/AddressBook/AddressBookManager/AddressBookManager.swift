//
//  AddressBookManager.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

typealias AddressBook = [AddressBookContact]

protocol AddressBookManager: Actor {
    var synchronizerState: AddressBookSynchronizerState { get async }

    func getAddressBook() async throws -> AddressBook

    func save(contact: AddressBookContact) async throws
    func remove(contact: AddressBookContact) async throws
}

enum AddressBookSynchronizerState: Hashable {
    case idle
    case syncing
    case synced
}
