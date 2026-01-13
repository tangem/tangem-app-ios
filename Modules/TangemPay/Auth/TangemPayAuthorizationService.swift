//
//  TangemPayAuthorizationService.swift
//  TangemPay
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

public protocol TangemPayAuthorizationService: TangemPayAuthorizationTokensHandler {
    func getChallenge(
        customerWalletAddress: String,
        customerWalletId: String
    ) async throws -> TangemPayGetChallengeResponse

    func getTokens(
        sessionId: String,
        signedChallenge: String,
        messageFormat: String
    ) async throws -> TangemPayAuthorizationTokens

    func refreshTokens(refreshToken: String) async throws(TangemPayAPIServiceError) -> TangemPayAuthorizationTokens
}
