//
//  AuthorizationTokensHolder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

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
    private(set) var tokensInfo: InternalAuthorizationTokens?

    init(authorizationTokens: VisaAuthorizationTokens? = nil) {
        guard
            let authorizationTokens,
            let tokensInfo = try? InternalAuthorizationTokens(bffTokens: authorizationTokens)
        else {
            self.tokensInfo = nil
            return
        }

        self.tokensInfo = tokensInfo
    }

    func setTokens(authorizationTokens: InternalAuthorizationTokens) {
        tokensInfo = authorizationTokens
    }
}
