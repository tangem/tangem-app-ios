//
//  UserWalletRegistrationClientError.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public enum UserWalletRegistrationClientError: Error {
    case requestNonceTimeout
    case requestNonceFailed(underlying: any Error)

    case registerFailed(underlying: any Error)
    case alreadyRegistered

    case unregisterFailed(underlying: any Error)
    case wasNotRegistered
}
