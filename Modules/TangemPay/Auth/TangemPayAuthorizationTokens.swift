//
//  TangemPayAuthorizationTokens.swift
//  TangemPay
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public struct TangemPayAuthorizationTokens: Codable, Equatable {
    public let accessToken: String
    public let refreshToken: String

    private let expiresAt: Date
    private let refreshExpiresAt: Date

    public init(accessToken: String, refreshToken: String, expiresAt: Date, refreshExpiresAt: Date) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresAt = expiresAt
        self.refreshExpiresAt = refreshExpiresAt
    }
}

public extension TangemPayAuthorizationTokens {
    var accessTokenExpired: Bool {
        Date().timeIntervalSince1970 > expiresAt.timeIntervalSince1970
    }

    var refreshTokenExpired: Bool {
        Date().timeIntervalSince1970 > refreshExpiresAt.timeIntervalSince1970
    }
}
