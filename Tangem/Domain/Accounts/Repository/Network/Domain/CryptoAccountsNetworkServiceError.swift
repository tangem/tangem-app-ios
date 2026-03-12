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
    /// Pretty much impossible case, when there are no retries left, but no error occurred.
    case noRetriesLeft
}

// MARK: - Convenience extensions

extension CryptoAccountsNetworkServiceError {
    var isCancellationError: Bool {
        switch self {
        case .underlyingError(let error):
            return error.isCancellationError
        case .missingRevision,
             .inconsistentState,
             .noAccountsCreated,
             .noRetriesLeft:
            return false
        }
    }

    var underlyingError: Error? {
        switch self {
        case .underlyingError(let error):
            return error
        case .missingRevision,
             .inconsistentState,
             .noAccountsCreated,
             .noRetriesLeft:
            return nil
        }
    }
}
