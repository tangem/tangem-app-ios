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
    func refreshAccessToken(refreshToken: String, authorizationType: VisaAuthorizationType) async throws -> VisaAuthorizationTokens
}

struct CommonVisaAuthorizationService {
    typealias AuthorizationAPIService = APIService<AuthorizationAPITarget>
    private let apiService: AuthorizationAPIService

    private let apiType: VisaAPIType

    init(apiType: VisaAPIType, apiService: AuthorizationAPIService) {
        self.apiType = apiType
        self.apiService = apiService
    }
}

extension CommonVisaAuthorizationService: VisaAuthorizationService {
    func getCardAuthorizationChallenge(cardId: String, cardPublicKey: String) async throws -> VisaAuthChallengeResponse {
        try await apiService.request(.init(
            target: .generateNonce(request: .init(
                cardId: cardId,
                cardPublicKey: cardPublicKey,
                cardWalletAddress: nil,
                authType: .cardId
            )),
            apiType: apiType
        ))
    }

    func getWalletAuthorizationChallenge(cardId: String, walletAddress: String) async throws -> VisaAuthChallengeResponse {
        try await apiService.request(.init(
            target: .generateNonce(request: .init(
                cardId: cardId,
                cardPublicKey: nil,
                cardWalletAddress: walletAddress,
                authType: .cardWallet
            )),
            apiType: apiType
        ))
    }

    func getAccessTokensForCardAuth(
        signedChallenge: String,
        salt: String,
        sessionId: String
    ) async throws -> VisaAuthorizationTokens {
        let dto: AuthorizationTokenDTO = try await apiService.request(.init(
            target: .getAuthorizationTokens(request: .init(
                signature: signedChallenge,
                salt: salt,
                sessionId: sessionId,
                authType: .cardId
            )),
            apiType: apiType
        ))

        return .init(dto: dto, authorizationType: .cardId)
    }

    func getAccessTokensForWalletAuth(signedChallenge: String, sessionId: String) async throws -> VisaAuthorizationTokens? {
        let dto: AuthorizationTokenDTO = try await apiService.request(.init(
            target: .getAuthorizationTokens(request: .init(
                signature: signedChallenge,
                salt: nil,
                sessionId: sessionId,
                authType: .cardWallet
            )),
            apiType: apiType
        ))

        return .init(dto: dto, authorizationType: .cardWallet)
    }
}

extension CommonVisaAuthorizationService: VisaAuthorizationTokenRefreshService {
    func refreshAccessToken(refreshToken: String, authorizationType: VisaAuthorizationType) async throws -> VisaAuthorizationTokens {
        try await apiService.request(.init(
            target: .refreshAuthorizationTokens(request: .init(
                refreshToken: refreshToken,
                authType: authorizationType
            )),
            apiType: apiType
        ))
    }
}
