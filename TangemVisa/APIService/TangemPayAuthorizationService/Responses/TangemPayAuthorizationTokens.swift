//
//  TangemPayAuthorizationTokens.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

public struct TangemPayAuthorizationTokens: Codable {
    public let accessToken: String
    public let refreshToken: String

    private let expiresAt: Date
    private let refreshExpiresAt: Date
}

public extension TangemPayAuthorizationTokens {
    var accessTokenExpired: Bool {
        Date().isAfterDate(expiresAt, granularity: .second)
    }

    var refreshTokenExpired: Bool {
        Date().isAfterDate(refreshExpiresAt, granularity: .second)
    }
}
