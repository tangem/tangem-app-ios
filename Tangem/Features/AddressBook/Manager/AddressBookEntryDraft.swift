//
//  AddressBookEntryDraft.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// User-entered address data before it is signed. The id is client-generated — entry ids are not part
/// of the signed tuple — and the manager assigns only the signature.
struct AddressBookEntryDraft: Hashable, Identifiable {
    let id: AddressEntryID
    let address: String
    let networkId: AddressBookNetworkID
    let memo: String?

    init(id: AddressEntryID = AddressEntryID(), address: String, networkId: AddressBookNetworkID, memo: String?) {
        self.id = id
        self.address = address
        self.networkId = networkId
        self.memo = memo
    }
}
