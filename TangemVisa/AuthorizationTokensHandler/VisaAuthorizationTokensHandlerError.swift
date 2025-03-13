//
//  VisaAuthorizationTokensHandlerError.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import TangemFoundation

public enum VisaAuthorizationTokensHandlerError {
    case authorizationTokensNotFound
    case refreshTokenExpired
    case missingMandatoryInfoInAccessToken
    case missingAccessToken
    case missingRefreshToken
    case accessTokenExpired
    case failedToUpdateAccessToken
}
