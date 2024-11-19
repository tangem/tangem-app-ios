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
    func getAuthorizationChallenge(cardId: String, cardPublicKey: String) async throws -> VisaAuthChallengeResponse
    func getAccessTokens(signedChallenge: String, salt: String, sessionId: String) async throws -> VisaAuthorizationTokens
}

protocol AccessTokenRefreshService {
    func refreshAccessToken(refreshToken: String) async throws -> VisaAuthorizationTokens
}

class CommonVisaAuthorizationService {
    private let apiService: APIService<AuthorizationAPITarget, VisaAuthorizationAPIError>

    init(
        provider: MoyaProvider<AuthorizationAPITarget>,
        logger: InternalLogger
    ) {
        apiService = .init(
            provider: provider,
            logger: logger,
            decoder: JSONDecoderFactory().makePayAPIDecoder()
        )
    }
}

extension CommonVisaAuthorizationService: VisaAuthorizationService {
    func getAuthorizationChallenge(cardId: String, cardPublicKey: String) async throws -> VisaAuthChallengeResponse {
        try await apiService.request(.init(
            target: .generateNonceByCID(cid: cardId, cardPublicKey: cardPublicKey)
        ))
    }

    func getAccessTokens(signedChallenge: String, salt: String, sessionId: String) async throws -> VisaAuthorizationTokens {
        try await apiService.request(.init(
            target: .getAccessToken(signature: signedChallenge, salt: salt, sessionId: sessionId)
        ))
    }
}

extension CommonVisaAuthorizationService: AccessTokenRefreshService {
    func refreshAccessToken(refreshToken: String) async throws -> VisaAuthorizationTokens {
        try await apiService.request(.init(
            target: .refreshAccessToken(refreshToken: refreshToken)
        ))
    }
}
