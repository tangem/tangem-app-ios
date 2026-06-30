//
//  AddressBookNetworkServiceError.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum AddressBookNetworkServiceError: LocalizedError {
    case underlyingError(Error)
    case inconsistentState
    case malformedResponse(Error)

    var errorDescription: String? {
        switch self {
        case .underlyingError(let error): error.localizedDescription
        case .inconsistentState: "Inconsistent state"
        case .malformedResponse(let error): error.localizedDescription
        }
    }
}
