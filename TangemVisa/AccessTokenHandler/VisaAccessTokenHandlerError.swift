//
//  VisaAccessTokenHandlerError.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public enum VisaAccessTokenHandlerError: String, LocalizedError {
    case authorizationTokensNotFound
    case refreshTokenExpired
    case missingMandatoryInfoInAccessToken
    case missingAccessToken
    case missingRefreshToken
    case accessTokenExpired
    case failedToUpdateAccessToken
}
