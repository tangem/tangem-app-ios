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
