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
    func getWalletAuthorizationChallenge(cardId: String, walletPublicKey: String) async throws -> VisaAuthChallengeResponse
    func getCustomerWalletAuthorizationChallenge(
        customerWalletAddress: String,
        customerWalletId: String
    ) async throws -> VisaAuthChallengeResponse
    func getAccessTokensForCardAuth(
        signedChallenge: String,
        salt: String,
        sessionId: String
    ) async throws -> VisaAuthorizationTokens
    func getAccessTokensForWalletAuth(
        signedChallenge: String,
        salt: String,
        sessionId: String
    ) async throws -> VisaAuthorizationTokens
    func getAccessTokensForCustomerWalletAuth(
        sessionId: String,
        signedChallenge: String,
        messageFormat: String
    ) async throws -> VisaAuthorizationTokens
}

public protocol VisaAuthorizationTokenRefreshService {
    func refreshAccessToken(refreshToken: String, authorizationType: VisaAuthorizationType) async throws -> VisaAuthorizationTokens
    func exchangeTokens(accessToken: String, refreshToken: String, authorizationType: VisaAuthorizationType) async throws -> VisaAuthorizationTokens
}

struct CommonVisaAuthorizationService {
    typealias AuthorizationAPIService = TangemPayAPIService<AuthorizationAPITarget>
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
                customerWalletAddress: nil,
                authType: .cardId
            )),
            apiType: apiType
        ))
    }

    func getWalletAuthorizationChallenge(cardId: String, walletPublicKey: String) async throws -> VisaAuthChallengeResponse {
        try await apiService.request(.init(
            target: .generateNonce(request: .init(
                cardId: cardId,
                cardPublicKey: nil,
                cardWalletAddress: walletPublicKey,
                customerWalletAddress: nil,
                authType: .cardWallet
            )),
            apiType: apiType
        ))
    }

    func getCustomerWalletAuthorizationChallenge(
        customerWalletAddress: String,
        customerWalletId: String
    ) async throws -> VisaAuthChallengeResponse {
        try await apiService.request(.init(
            target: .generateNonce(request: .init(
                cardId: nil,
                cardPublicKey: nil,
                cardWalletAddress: nil,
                customerWalletAddress: customerWalletAddress,
                authType: .customerWallet
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
                authType: .cardId,
                messageFormat: nil
            )),
            apiType: apiType
        ))

        return .init(dto: dto, authorizationType: .cardId)
    }

    func getAccessTokensForWalletAuth(
        signedChallenge: String,
        salt: String,
        sessionId: String
    ) async throws -> VisaAuthorizationTokens {
        let dto: AuthorizationTokenDTO = try await apiService.request(.init(
            target: .getAuthorizationTokens(request: .init(
                signature: signedChallenge,
                salt: salt,
                sessionId: sessionId,
                authType: .cardWallet,
                messageFormat: nil
            )),
            apiType: apiType
        ))

        return .init(dto: dto, authorizationType: .cardWallet)
    }

    func getAccessTokensForCustomerWalletAuth(
        sessionId: String,
        signedChallenge: String,
        messageFormat: String
    ) async throws -> VisaAuthorizationTokens {
        let dto: AuthorizationTokenDTO = try await apiService.request(.init(
            target: .getAuthorizationTokens(request: .init(
                signature: signedChallenge,
                salt: nil,
                sessionId: sessionId,
                authType: .customerWallet,
                messageFormat: messageFormat
            )),
            apiType: apiType
        ))

        return .init(dto: dto, authorizationType: .customerWallet)
    }
}

extension CommonVisaAuthorizationService: VisaAuthorizationTokenRefreshService {
    func refreshAccessToken(refreshToken: String, authorizationType: VisaAuthorizationType) async throws -> VisaAuthorizationTokens {
        let dto: AuthorizationTokenDTO = try await apiService.request(.init(
            target: .refreshAuthorizationTokens(request: .init(
                refreshToken: refreshToken,
                authType: authorizationType
            )),
            apiType: apiType
        ))

        return .init(dto: dto, authorizationType: authorizationType)
    }

    func exchangeTokens(accessToken: String, refreshToken: String, authorizationType: VisaAuthorizationType) async throws -> VisaAuthorizationTokens {
        let dto: AuthorizationTokenDTO = try await apiService.request(.init(
            target: .exchangeAuthorizationTokens(
                request: .init(accessToken: accessToken, refreshToken: refreshToken)
            ),
            apiType: apiType
        ))
        return .init(dto: dto, authorizationType: authorizationType)
    }
}
