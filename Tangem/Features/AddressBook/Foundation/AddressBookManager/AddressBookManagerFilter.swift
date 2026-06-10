//
//  AddressBookManagerFilter.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

protocol AddressBookManagerFilter {
    func getContacts(for network: BSDKBlockchain) async -> [AddressBookContact]
}
