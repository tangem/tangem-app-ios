//
//  AddressBookAddress.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

struct AddressBookAddress: Codable, Hashable {
    let address: String
    let memo: String?

    let networks: [BlockchainNetwork]
}
