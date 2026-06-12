//
//  AddressBookPlaintext.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// The decrypted blob contents — the full contact list, serialized to JSON and encrypted as a whole.
struct AddressBookPlaintext: Hashable, Codable {
    var contacts: [DecodedContact]

    init(contacts: [DecodedContact] = []) {
        self.contacts = contacts
    }
}
