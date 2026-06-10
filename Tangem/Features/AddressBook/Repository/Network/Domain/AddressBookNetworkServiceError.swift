//
//  AddressBookNetworkServiceError.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum AddressBookNetworkServiceError: Error {
    /// A revision (i.e. the `ETag` header) is missing when trying to save the contacts.
    case missingRevision
    /// The revision (i.e. the `ETag` header) is outdated when trying to save the contacts.
    case inconsistentState
    /// The remote API is not implemented yet. Temporary case for the stubbed network service.
    case notImplemented
    /// Other underlying errors (network errors, etc).
    case underlyingError(Error)
}

// MARK: - Convenience extensions

extension AddressBookNetworkServiceError {
    var isCancellationError: Bool {
        switch self {
        case .underlyingError(let error):
            return error.isCancellationError
        case .missingRevision,
             .inconsistentState,
             .notImplemented:
            return false
        }
    }

    var underlyingError: Error? {
        switch self {
        case .underlyingError(let error):
            return error
        case .missingRevision,
             .inconsistentState,
             .notImplemented:
            return nil
        }
    }
}
