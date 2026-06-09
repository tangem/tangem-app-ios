//
//  AddressBookContact.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

struct AddressBookContact: Codable, Hashable {
    let name: String
    let icon: String
    let addresses: [AddressBookAddress]
}
