//
//  AddressBookEntryDraft.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

/// User-entered address data before it is signed. The id is client-generated — entry ids are not part
/// of the signed tuple — and the manager assigns only the signature.
struct AddressBookEntryDraft: AddressBookEntry, Identifiable {
    let id: AddressBookAddressEntryID
    let address: String
    let blockchain: BSDKBlockchain
    let memo: String?

    init(id: AddressBookAddressEntryID = AddressBookAddressEntryID(), address: String, blockchain: BSDKBlockchain, memo: String?) {
        self.id = id
        self.address = address
        self.blockchain = blockchain
        self.memo = memo
    }
}
