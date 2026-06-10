//
//  AddressBookManagerFilter.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

protocol AddressBookManagerFilter {
    func getAddressBook(filteredFor network: BSDKBlockchain) async -> AddressBook
}
