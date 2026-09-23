//
//  SessionTokens+fake.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct Foundation.Data
import struct Foundation.Date
import struct Foundation.UUID
import struct TangemFoundation.UserWalletId
@testable import TangemBackendAuthentication

extension SessionTokens {
    static let fake = SessionTokens(
        accessToken: Token(jwt: "access-jwt", expiresAt: Date.fake),
        refreshToken: Token(jwt: "refresh-jwt", expiresAt: Date.fake),
        userWalletIDs: []
    )

    static func uniqueFake() -> SessionTokens {
        SessionTokens(
            accessToken: Token(jwt: "access-jwt-\(UUID().uuidString)", expiresAt: Date.fake),
            refreshToken: Token(jwt: "refresh-jwt-\(UUID().uuidString)", expiresAt: Date.fake),
            userWalletIDs: [UserWalletId(value: Data(UUID().uuidString.utf8))]
        )
    }
}
