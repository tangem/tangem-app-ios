//
//  TangemPayAuthorizationTokensHandler.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import JWTDecode

struct TangemPayAuthorizationTokensHandler: VisaAuthorizationTokensHandler {
    let authorizationTokensHolder: AuthorizationTokensHolder

    var accessToken: JWT? {
        get async { await authorizationTokensHolder.tokensInfo?.jwtTokens.accessToken }
    }

    var accessTokenExpired: Bool {
        get async { await authorizationTokensHolder.tokensInfo?.jwtTokens.accessToken?.expired ?? true }
    }

    var refreshTokenExpired: Bool {
        get async { await authorizationTokensHolder.tokensInfo?.jwtTokens.refreshToken.expired ?? true }
    }

    var containsAccessToken: Bool {
        get async { await authorizationTokensHolder.tokensInfo != nil }
    }

    var authorizationHeader: String {
        get async throws {
            guard let tokens = await authorizationTokensHolder.tokensInfo else {
                throw VisaAuthorizationTokensHandlerError.missingAccessToken
            }

            return try AuthorizationTokensUtility().getAuthorizationHeader(from: tokens.jwtTokens)
        }
    }

    var authorizationTokens: VisaAuthorizationTokens? {
        get async { await authorizationTokensHolder.tokensInfo?.bffTokens }
    }

    func setupTokens(_ tokens: VisaAuthorizationTokens) async throws {
        let authTokens = try InternalAuthorizationTokens(bffTokens: tokens)
        try await authorizationTokensHolder.setTokens(authorizationTokens: authTokens)
    }

    // [REDACTED_TODO_COMMENT]
    func forceRefreshToken() async throws {}
    func exchageTokens() async throws {}
    func setupRefreshTokenSaver(_ refreshTokenSaver: any VisaRefreshTokenSaver) {}
}
