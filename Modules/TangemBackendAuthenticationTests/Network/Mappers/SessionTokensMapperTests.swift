//
//  SessionTokensMapperTests.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct Foundation.Data
import struct Foundation.Date
import Testing
import struct TangemFoundation.UserWalletId
@testable import TangemBackendAuthentication

@Suite(.tags(.backendAuthentication))
struct SessionTokensMapperTests {
    @Test
    func mapToDomainMapsAccessAndRefreshTokensWhenBothPresent() {
        let accessTokenExpiresAt = Date(timeIntervalSince1970: 1000)
        let refreshTokenExpiresAt = Date(timeIntervalSince1970: 2000)

        let response = TokensDTO.Response(
            accessToken: "some-access-jwt",
            accessTokenExpiresAt: accessTokenExpiresAt,
            refreshToken: "some-refresh-jwt",
            refreshTokenExpiresAt: refreshTokenExpiresAt,
            walletIds: []
        )

        let sessionTokens = SessionTokensMapper.mapToDomain(response)

        #expect(sessionTokens.accessToken == SessionTokens.Token(jwt: "some-access-jwt", expiresAt: accessTokenExpiresAt))
        #expect(sessionTokens.refreshToken == SessionTokens.Token(jwt: "some-refresh-jwt", expiresAt: refreshTokenExpiresAt))
    }

    @Test
    func mapToDomainOmitsRefreshTokenWhenExpiryIsMissing() {
        let response = TokensDTO.Response(
            accessToken: "any-access-jwt",
            accessTokenExpiresAt: Date(timeIntervalSince1970: 1000),
            refreshToken: "any-refresh-jwt",
            refreshTokenExpiresAt: nil,
            walletIds: []
        )

        #expect(SessionTokensMapper.mapToDomain(response).refreshToken == nil)
    }

    @Test
    func mapToDomainOmitsRefreshTokenWhenJWTIsMissing() {
        let response = TokensDTO.Response(
            accessToken: "any-access-jwt",
            accessTokenExpiresAt: Date(timeIntervalSince1970: 1000),
            refreshToken: nil,
            refreshTokenExpiresAt: Date(timeIntervalSince1970: 2000),
            walletIds: []
        )

        #expect(SessionTokensMapper.mapToDomain(response).refreshToken == nil)
    }

    @Test
    func mapToDomainDecodesValidBase64WalletIDs() {
        let firstWalletIDData = Data([0x01, 0x02, 0x03])
        let secondWalletIDData = Data([0x04, 0x05, 0x06])

        let response = TokensDTO.Response(
            accessToken: "any-access-jwt",
            accessTokenExpiresAt: Date(timeIntervalSince1970: 1000),
            refreshToken: nil,
            refreshTokenExpiresAt: nil,
            walletIds: [
                firstWalletIDData.base64EncodedString(),
                secondWalletIDData.base64EncodedString(),
            ]
        )

        let userWalletIDs = SessionTokensMapper.mapToDomain(response).userWalletIDs

        #expect(userWalletIDs == [UserWalletId(value: firstWalletIDData), UserWalletId(value: secondWalletIDData)])
    }

    @Test
    func mapToDomainDropsWalletIDsThatFailToDecode() {
        let validWalletIDData = Data([0x01, 0x02, 0x03])

        let response = TokensDTO.Response(
            accessToken: "any-access-jwt",
            accessTokenExpiresAt: Date(timeIntervalSince1970: 1000),
            refreshToken: nil,
            refreshTokenExpiresAt: nil,
            walletIds: ["invalid base64 string", validWalletIDData.base64EncodedString()]
        )

        let userWalletIDs = SessionTokensMapper.mapToDomain(response).userWalletIDs

        #expect(userWalletIDs == [UserWalletId(value: validWalletIDData)])
    }
}
