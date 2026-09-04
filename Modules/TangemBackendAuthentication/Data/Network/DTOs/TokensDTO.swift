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
    /// - Important: Date is in ISO-8601 format. Should be decoded with `JSONDecoder.DateDecodingStrategy.iso8601`.
    struct Response: Decodable {
        let accessToken: String
        let accessTokenExpiresAt: Date

        let refreshToken: String?
        let refreshTokenExpiresAt: Date?

        let walletIds: [String]
    }
}
