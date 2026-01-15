//
//  TangemPayAuthorizationService.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

public protocol TangemPayAuthorizationService: TangemPayAuthorizationTokensHandler {
    func getChallenge(
        customerWalletAddress: String,
        customerWalletId: String
    ) async throws(TangemPayAPIServiceError) -> TangemPayGetChallengeResponse

    func getTokens(
        sessionId: String,
        signedChallenge: String,
        messageFormat: String
    ) async throws(TangemPayAPIServiceError) -> TangemPayAuthorizationTokens
}
