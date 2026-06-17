//
//  AddressBookEntry.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Shared shape of an address-book entry — a single (address, network, memo) tuple with a
/// client-generated id. Conformed by the editable `AddressBookEntryDraft` and the verified
/// `AddressBookVerifiedAddressEntry`, so `AddressBookContactEntries` can hold either kind.
protocol AddressBookEntry: Hashable {
    var id: AddressBookAddressEntryID { get }
    var address: String { get }
    var networkId: AddressBookNetworkID { get }
    var memo: String? { get }
}
