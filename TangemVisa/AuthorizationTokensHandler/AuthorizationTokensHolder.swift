//
//  AuthorizationTokensHolder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct InternalAuthorizationTokens {
    let bffTokens: VisaAuthorizationTokens
    let jwtTokens: DecodedAuthorizationJWTTokens

    init(bffTokens: VisaAuthorizationTokens) throws {
        let decodedJWTTokens = try AuthorizationTokensUtility().decodeAuthTokens(bffTokens)
        self.bffTokens = bffTokens
        jwtTokens = decodedJWTTokens
    }
}

actor AuthorizationTokensHolder {
    private var authTokensInfo: InternalAuthorizationTokens?

    var tokensInfo: InternalAuthorizationTokens? {
        get async {
            authTokensInfo
        }
    }

    init(authorizationTokens: VisaAuthorizationTokens? = nil) {
        guard
            let authorizationTokens,
            let tokensInfo = try? InternalAuthorizationTokens(bffTokens: authorizationTokens)
        else {
            return
        }

        authTokensInfo = tokensInfo
    }

    func setTokens(authorizationTokens: InternalAuthorizationTokens) async throws {
        authTokensInfo = authorizationTokens
    }
}
