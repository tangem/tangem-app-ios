//
//  AuthorizationTokensUtility.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import JWTDecode

struct AuthorizationTokensUtility {
    func decodeAuthTokens(_ tokens: VisaAuthorizationTokens) throws -> DecodedAuthorizationJWTTokens {
        var accessToken: JWT?
        if let token = tokens.accessToken {
            let decodedAccessToken = try decode(jwt: token)
            accessToken = decodedAccessToken
        }
        let refreshToken = try decode(jwt: tokens.refreshToken)
        return .init(accessToken: accessToken, refreshToken: refreshToken)
    }

    func getAuthorizationHeader(from tokens: VisaAuthorizationTokens) throws (VisaAuthorizationTokensHandlerError) -> String {
        guard let accessToken = tokens.accessToken else {
            throw .missingAccessToken
        }

        return VisaConstants.authorizationHeaderValuePrefix + accessToken
    }

    func getAuthorizationHeader(from tokens: DecodedAuthorizationJWTTokens) throws (VisaAuthorizationTokensHandlerError) -> String {
        guard let accessToken = tokens.accessToken?.string else {
            throw .missingAccessToken
        }

        return VisaConstants.authorizationHeaderValuePrefix + accessToken
    }
}

struct DecodedAuthorizationJWTTokens {
    var accessToken: JWT?
    var refreshToken: JWT
}
