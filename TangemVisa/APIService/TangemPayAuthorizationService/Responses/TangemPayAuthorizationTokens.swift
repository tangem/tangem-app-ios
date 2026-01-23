//
//  TangemPayAuthorizationTokens.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

public struct TangemPayAuthorizationTokens: Codable, Equatable {
    public let accessToken: String
    public let refreshToken: String

    private let expiresAt: Date
    private let refreshExpiresAt: Date

    public init(
        accessToken: String,
        refreshToken: String,
        expiresAt: Date,
        refreshExpiresAt: Date
    ) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresAt = expiresAt
        self.refreshExpiresAt = refreshExpiresAt
    }
}

public extension TangemPayAuthorizationTokens {
    var accessTokenExpired: Bool {
        Date().isAfterDate(expiresAt, granularity: .second)
    }

    var refreshTokenExpired: Bool {
        Date().isAfterDate(refreshExpiresAt, granularity: .second)
    }
}
