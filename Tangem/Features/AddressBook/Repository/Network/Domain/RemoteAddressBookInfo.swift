//
//  RemoteAddressBookInfo.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

struct RemoteAddressBookInfo {
    let addressBook: AddressBook
    /// Book-level revision (the `ETag` header) the server reports for this address book.
    let version: String?
}
