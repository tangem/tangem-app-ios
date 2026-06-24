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
struct AddressBookEntryDraft: AddressBookEntry, Identifiable {
    let id: AddressBookAddressEntryID
    let address: String
    let networkId: AddressBookNetworkID
    let memo: String?

    init(id: AddressBookAddressEntryID = AddressBookAddressEntryID(), address: String, networkId: AddressBookNetworkID, memo: String?) {
        self.id = id
        self.address = address
        self.networkId = networkId
        self.memo = memo
    }
}
