//
//  RemoteAddressBook.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// A fetched address book: the server-assigned opaque `etag` (used for optimistic locking) plus its
/// envelope.
struct RemoteAddressBook: Hashable {
    let etag: String
    let envelope: AddressBookEnvelope
}
