//
//  SessionTokens+fake.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct Foundation.Date
@testable import TangemBackendAuthentication

extension SessionTokens {
    static let fake = SessionTokens(
        accessToken: Token(jwt: "access-jwt", expiresAt: Date.fake),
        refreshToken: Token(jwt: "refresh-jwt", expiresAt: Date.fake),
        userWalletIDs: []
    )
}
