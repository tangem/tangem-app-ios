//
//  AddressBookEntryDraft.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// User-entered address data before it is signed. The manager assigns the id and signature.
struct AddressBookEntryDraft: Hashable {
    let address: String
    let networkId: AddressBookNetworkID
    let memo: String?
}
