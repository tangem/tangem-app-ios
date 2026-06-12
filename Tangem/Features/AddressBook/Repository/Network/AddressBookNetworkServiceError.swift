//
//  AddressBookNetworkServiceError.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum AddressBookNetworkServiceError: Error {
    case underlyingError(Error)
    /// Optimistic-locking (`If-Match`) failure — the server has a newer revision. Reserved for the
    /// real backend integration (T4); the repository refetches and reapplies the local mutation.
    case inconsistentState
    case noRetriesLeft
}
