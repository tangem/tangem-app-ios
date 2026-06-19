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
    /// Optimistic-locking (`If-Match`) failure — the server has a newer revision. The repository
    /// refetches the current etag and replays the local mutation.
    case inconsistentState
    /// The conflict-resolution retries are exhausted — the local mutation keeps colliding with newer
    /// server revisions.
    case noRetriesLeft
}
