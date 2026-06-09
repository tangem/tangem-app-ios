//
//  AddressBookManager.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

protocol AddressBookManager: Actor {
    var synchronizerState: AddressBookSynchronizerState { get }

    func getAddresses() async throws -> [AddressBookContact]

    func save(contact: AddressBookContact) async throws
    func remove(contact: AddressBookContact) async throws
}

enum AddressBookSynchronizerState: Hashable {
    case idle
    case syncing
    case synced
}
