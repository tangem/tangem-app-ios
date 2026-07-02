//
//  AddressBookSyncState.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum AddressBookSyncState {
    case syncing
    case synced
    case failure(AddressBookSyncError)
}

enum AddressBookSyncError: LocalizedError {
    case networkError(String)
    case decodingError(String)
    case updateRequired

    var errorDescription: String? {
        switch self {
        case .networkError(let description): description
        case .decodingError(let description): description
        case .updateRequired: "Address book requires a newer app version"
        }
    }
}
