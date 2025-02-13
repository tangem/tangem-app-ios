//
//  VisaAuthorizationService.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Moya

public protocol VisaAuthorizationService {
    func getCardAuthorizationChallenge(cardId: String, cardPublicKey: String) async throws -> VisaAuthChallengeResponse
    func getWalletAuthorizationChallenge(cardId: String, walletAddress: String) async throws -> VisaAuthChallengeResponse
    func getAccessTokensForCardAuth(
        signedChallenge: String,
        salt: String,
        sessionId: String
    ) async throws -> VisaAuthorizationTokens
    func getAccessTokensForWalletAuth(signedChallenge: String, sessionId: String) async throws -> VisaAuthorizationTokens?
}

public protocol VisaAuthorizationTokenRefreshService {
    func refreshAccessToken(refreshToken: String) async throws -> VisaAuthorizationTokens
}

struct CommonVisaAuthorizationService {
    typealias AuthorizationAPIService = APIService<AuthorizationAPITarget, VisaAuthorizationAPIError>
    private let apiService: AuthorizationAPIService

    init(apiService: AuthorizationAPIService) {
        self.apiService = apiService
    }
}

extension CommonVisaAuthorizationService: VisaAuthorizationService {
    func getCardAuthorizationChallenge(cardId: String, cardPublicKey: String) async throws -> VisaAuthChallengeResponse {
        try await apiService.request(.init(
            target: .generateNonceByCID(cid: cardId, cardPublicKey: cardPublicKey)
        ))
    }

    func getWalletAuthorizationChallenge(cardId: String, walletAddress: String) async throws -> VisaAuthChallengeResponse {
        try await apiService.request(.init(
            target: .generateNonceForWallet(cid: cardId, walletAddress: walletAddress)
        ))
    }

    func getAccessTokensForCardAuth(
        signedChallenge: String,
        salt: String,
        sessionId: String
    ) async throws -> VisaAuthorizationTokens {
        try await apiService.request(.init(
            target: .getAccessTokenForCardAuth(signature: signedChallenge, salt: salt, sessionId: sessionId)
        ))
    }

    func getAccessTokensForWalletAuth(signedChallenge: String, sessionId: String) async throws -> VisaAuthorizationTokens? {
        try await apiService.request(.init(
            target: .getAccessTokenForWalletAuth(signature: signedChallenge, sessionId: sessionId)
        ))
    }
}

extension CommonVisaAuthorizationService: VisaAuthorizationTokenRefreshService {
    func refreshAccessToken(refreshToken: String) async throws -> VisaAuthorizationTokens {
        try await apiService.request(.init(
            target: .refreshAccessToken(refreshToken: refreshToken)
        ))
    }
}
