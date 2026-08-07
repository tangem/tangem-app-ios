//
//  AddressBookFetchResult.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum AddressBookFetchResult: Hashable {
    case notModified
    case notFound
    case fetched(RemoteAddressBook)
}
