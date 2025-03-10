//
//  VisaAuthorizationTokensHandlerError.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import TangemFoundation

public enum VisaAuthorizationTokensHandlerError: Int, TangemError {
    case authorizationTokensNotFound = 1
    case refreshTokenExpired
    case missingMandatoryInfoInAccessToken
    case missingAccessToken
    case missingRefreshToken
    case accessTokenExpired
    case failedToUpdateAccessToken

    public var subsystemCode: Int { VisaSubsystem.authorizationTokensHandler.rawValue }
}
