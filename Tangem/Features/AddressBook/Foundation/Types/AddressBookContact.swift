//
//  AddressBookContact.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct AddressBookContact: Codable, Hashable {
    let id: UUID
    let name: String
    let icon: String
    let addresses: [AddressBookAddress]
}
