//
//  TokensResponseFixture.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

enum TokensResponseFixture {
    static func valid(accessToken: String, refreshToken: String) -> String {
        """
        {
            "accessToken": "\(accessToken)",
            "accessTokenExpiresAt": "2026-01-01T00:00:00Z",
            "refreshToken": "\(refreshToken)",
            "refreshTokenExpiresAt": "2026-02-01T00:00:00.454138590Z",
            "walletIds": []
        }
        """
    }

    static let invalidWithUnixTimestampDateFormat = """
    {
        "accessToken": "access-jwt",
        "accessTokenExpiresAt": "1767225600",
        "refreshToken": "refresh-jwt",
        "refreshTokenExpiresAt": "1767225600",
        "walletIds": []
    }
    """
}
