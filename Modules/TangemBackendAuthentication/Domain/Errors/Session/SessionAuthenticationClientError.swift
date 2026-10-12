//
//  SessionAuthenticationClientError.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

enum SessionAuthenticationClientError: Error {
    case requestNonceTimeout
    case requestNonceFailed(underlying: any Error)

    case authenticateFailed(underlying: any Error)
    case authenticationRejected
    case deviceRegistrationMissing

    case refreshFailed(underlying: any Error)
}
