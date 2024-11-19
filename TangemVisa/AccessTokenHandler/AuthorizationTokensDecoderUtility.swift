//
//  AuthorizationTokensDecoderUtility.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import JWTDecode

struct AuthorizationTokensDecoderUtility {
    func decodeAuthTokens(_ tokens: VisaAuthorizationTokens) throws -> DecodedAuthorizationJWTTokens {
        let accessToken = try decode(jwt: tokens.accessToken)
        let refreshToken = try decode(jwt: tokens.refreshToken)
        return .init(accessToken: accessToken, refreshToken: refreshToken)
    }
}

struct DecodedAuthorizationJWTTokens {
    var accessToken: JWT
    var refreshToken: JWT
}
