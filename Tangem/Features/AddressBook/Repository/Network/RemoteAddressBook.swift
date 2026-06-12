//
//  RemoteAddressBook.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// A fetched address book: the server-assigned `etag` (= `SHA-256(ciphertext)`) plus its envelope.
struct RemoteAddressBook: Hashable {
    let etag: String
    let envelope: AddressBookEnvelope
}
