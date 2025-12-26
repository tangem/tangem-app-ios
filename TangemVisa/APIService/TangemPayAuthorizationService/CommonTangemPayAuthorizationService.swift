//
//  CommonTangemPayAuthorizationService.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemSdk

public protocol TangemPayAuthorizing: AnyObject {
    func authorize(
        customerWalletId: String,
        authorizationService: TangemPayAuthorizationService
    ) async throws -> TangemPayAuthorizingResponse
}

public struct TangemPayAuthorizingResponse {
    public let customerWalletAddress: String
    public let tokens: TangemPayAuthorizationTokens

    public init(customerWalletAddress: String, tokens: TangemPayAuthorizationTokens) {
        self.customerWalletAddress = customerWalletAddress
        self.tokens = tokens
    }
}

struct CommonTangemPayAuthorizationService {
    private let customerWalletId: String
    private let authorizingInteractor: TangemPayAuthorizing

    private let apiType: VisaAPIType
    private let apiService: TangemPayAPIService<TangemPayAuthorizationAPITarget>

    init(
        customerWalletId: String,
        authorizingInteractor: TangemPayAuthorizing,
        apiType: VisaAPIType,
        apiService: TangemPayAPIService<TangemPayAuthorizationAPITarget>
    ) {
        self.customerWalletId = customerWalletId
        self.authorizingInteractor = authorizingInteractor
        self.apiType = apiType
        self.apiService = apiService
    }
}

extension CommonTangemPayAuthorizationService: TangemPayAuthorizationService {
    func authorizeWithCustomerWallet() async throws -> TangemPayAuthorizingResponse {
        try await authorizingInteractor.authorize(
            customerWalletId: customerWalletId,
            authorizationService: self
        )
    }

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

    func refreshTokens(refreshToken: String) async throws(TangemPayAPIServiceError) -> TangemPayAuthorizationTokens {
        try await apiService.request(.init(
            target: .refreshTokens(.init(refreshToken: refreshToken)),
            apiType: apiType
        ))
    }
}
