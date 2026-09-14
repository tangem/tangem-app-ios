//
//  SessionTokens.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public import struct Foundation.Date
public import struct TangemFoundation.UserWalletId

/// The pair of JWTs issued by the backend on device registration or authentication,
/// together with the user wallets that session grants access to.
public struct SessionTokens: Equatable, Sendable {
    /// Short-lived token (5–15 minutes) sent as `Authorization: DPoP <jwt>` on session-authenticated requests.
    public let accessToken: Token

    /// Long-lived token (7–30 days) exchanged for a new ``accessToken`` via `POST /mobile/token/refresh`.
    public let refreshToken: Token?

    /// The user wallets this session grants access to.
    public let userWalletIDs: [UserWalletId]
}

public extension SessionTokens {
    /// `JSON Web Token` together with the point in time it stops being valid.
    struct Token: Equatable, Sendable {
        /// Token value in [RFC 7519 JWT](https://www.rfc-editor.org/info/rfc7519/) standard.
        public let jwt: String

        /// When the token stops being valid.
        public let expiresAt: Date
    }
}
