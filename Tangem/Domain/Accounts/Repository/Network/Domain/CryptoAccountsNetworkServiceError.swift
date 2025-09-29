//
//  CryptoAccountsNetworkServiceError.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

enum CryptoAccountsNetworkServiceError: Error {
    /// A revision (i.e. the `ETag` header) is missing when trying to save the accounts.
    case missingRevision
    /// The revision (i.e. the `ETag` header) is outdated when trying to save the accounts.
    case inconsistentState
    /// No accounts were created on the server when trying to fetch the accounts.
    case noAccountsCreated
    /// Other underlying errors (network errors, etc).
    case underlyingError(Error)
}
