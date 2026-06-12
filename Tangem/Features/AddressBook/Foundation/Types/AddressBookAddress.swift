//
//  AddressBookAddress.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct AddressBookAddress: Codable, Hashable {
    let id: UUID
    let networkId: String
    let address: String
    let memo: String?
    let signature: String
}
