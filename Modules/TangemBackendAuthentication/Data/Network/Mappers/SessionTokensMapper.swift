//
//  SessionTokensMapper.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

private import struct Foundation.Data
private import struct TangemFoundation.UserWalletId

enum SessionTokensMapper {
    static func mapToDomain(_ tokensResponse: TokensDTO.Response) -> SessionTokens {
        let accessToken = SessionTokens.Token(jwt: tokensResponse.accessToken, expiresAt: tokensResponse.accessTokenExpiresAt)
        let refreshToken: SessionTokens.Token?

        if let refreshTokenJWT = tokensResponse.refreshToken, let refreshTokenExpiresAt = tokensResponse.refreshTokenExpiresAt {
            refreshToken = SessionTokens.Token(jwt: refreshTokenJWT, expiresAt: refreshTokenExpiresAt)
        } else {
            refreshToken = nil
        }

        let userWalletIDs = tokensResponse.walletIds.compactMap { rawWalletID in
            Data(base64Encoded: rawWalletID).map(UserWalletId.init(value:))
        }

        return SessionTokens(accessToken: accessToken, refreshToken: refreshToken, userWalletIDs: userWalletIDs)
    }
}
