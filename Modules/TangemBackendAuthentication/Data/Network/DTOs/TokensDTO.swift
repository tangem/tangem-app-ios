//
//  TokensDTO.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct Foundation.Date

/// `POST api/authentication/v1/mobile/register`
/// `POST api/authentication/v1/mobile/wallet/register`
/// `POST api/authentication/v1/mobile/wallet/unregister`
/// `POST api/authentication/v1/mobile/authenticate`
/// `POST api/authentication/v1/mobile/token/refresh`
enum TokensDTO {
    /// - Important: Dates are expected to be in ISO-8601 format, optionally with fractional seconds (0, 3, 6, or 9 digits).
    /// For example:
    /// - `2021-03-23T15:30:00Z`
    /// - `2021-03-23T15:30:00.454138Z`
    struct Response: Decodable {
        let accessToken: String
        let accessTokenExpiresAt: Date

        let refreshToken: String?
        let refreshTokenExpiresAt: Date?

        let walletIds: [String]
    }
}
