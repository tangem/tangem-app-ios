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

class AuthorizationTokensHolder {
    private var authTokensInfo: ThreadSafeContainer<InternalAuthorizationTokens?>

    var tokensInfo: InternalAuthorizationTokens? {
        authTokensInfo.read()
    }

    init(authorizationTokens: VisaAuthorizationTokens? = nil) {
        guard
            let authorizationTokens,
            let tokensInfo = try? InternalAuthorizationTokens(bffTokens: authorizationTokens)
        else {
            authTokensInfo = .init(nil)
            return
        }

        authTokensInfo = .init(tokensInfo)
    }

    func setTokens(authorizationTokens: InternalAuthorizationTokens) async throws {
        authTokensInfo.mutate { value in
            value = authorizationTokens
        }
    }
}
