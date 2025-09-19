//
//  CryptoAccountsNetworkServiceError.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

enum CryptoAccountsNetworkServiceError: Error {
    case noAccountsCreated
    case inconsistentState
    case underlyingError(Error)
}
