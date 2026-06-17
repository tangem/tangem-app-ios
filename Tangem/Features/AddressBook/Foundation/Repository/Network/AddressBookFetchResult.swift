//
//  AddressBookFetchResult.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum AddressBookFetchResult: Hashable {
    /// The known etag matches the server version — the caller keeps using its local cache.
    case notModified
    /// No book exists for this wallet yet. The caller treats the book as empty.
    case notFound
    case fetched(RemoteAddressBook)
}
