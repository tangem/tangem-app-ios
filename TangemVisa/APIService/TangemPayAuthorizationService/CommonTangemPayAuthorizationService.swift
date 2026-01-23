//
//  CommonTangemPayAuthorizationService.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

struct CommonTangemPayAuthorizationService {
    typealias AuthorizationAPIService = TangemPayAPIService<TangemPayAuthorizationAPITarget>
    private let apiService: AuthorizationAPIService

    private let apiType: VisaAPIType

    init(apiType: VisaAPIType, apiService: AuthorizationAPIService) {
        self.apiType = apiType
        self.apiService = apiService
    }
}

extension CommonTangemPayAuthorizationService: TangemPayAuthorizationService {
    func getChallenge(
        customerWalletAddress: String,
        customerWalletId: String
    ) async throws -> TangemPayGetChallengeResponse {
        try await apiService.request(.init(
            target: .getChallenge(.init(
                customerWalletAddress: customerWalletAddress,
                customerWalletId: customerWalletId
            )),
            apiType: apiType
        ))
    }

    func getTokens(
        sessionId: String,
        signedChallenge: String,
        messageFormat: String
    ) async throws -> TangemPayAuthorizationTokens {
        try await apiService.request(.init(
            target: .getTokens(.init(
                signature: signedChallenge,
                sessionId: sessionId,
                messageFormat: messageFormat
            )),
            apiType: apiType
        ))
    }

    func refreshTokens(
        refreshToken: String
    ) async throws -> TangemPayAuthorizationTokens {
        try await apiService.request(.init(
            target: .refreshTokens(
                request: .init(refreshToken: refreshToken)
            ),
            apiType: apiType
        ))
    }
}
