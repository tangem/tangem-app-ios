//
//  TangemPayAuthorizationService.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine

public enum TangemPayApiErrorEvent {
    case unauthorized
    case other
}

public protocol TangemPayAuthorizationTokensHandler: AnyObject {
    var refreshTokenExpired: Bool { get }
    var authorizationHeader: String? { get }
    var errorEventPublisher: AnyPublisher<TangemPayApiErrorEvent, Never> { get }

    func saveTokens(tokens: TangemPayAuthorizationTokens) throws
    func prepare() async throws
}

public protocol TangemPayAuthorizationService: TangemPayAuthorizationTokensHandler {
    func authorizeWithCustomerWallet() async throws

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
