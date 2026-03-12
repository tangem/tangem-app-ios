//
//  CommonPaymentAccountAuthorizationService.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemFoundation

public protocol PaymentAccountAuthorizationTokensRepository {
    func save(tokens: TangemPayAuthorizationTokens, customerWalletId: String) throws
    func deleteTokens(customerWalletId: String) throws
    func getToken(forCustomerWalletId customerWalletId: String) -> TangemPayAuthorizationTokens?
}

final class CommonPaymentAccountAuthorizationService {
    private let customerWalletId: String
    private let authorizationTokensRepository: PaymentAccountAuthorizationTokensRepository

    private let apiType: VisaAPIType
    private let apiService: TangemPayAPIService<TangemPayAuthorizationAPITarget>

    private let authorizationTokensHolder: ThreadSafeContainer<TangemPayAuthorizationTokens?>
    private let taskProcessor = SingleTaskProcessor<Void, TangemPayAPIServiceError>()

    private var tokens: TangemPayAuthorizationTokens? {
        authorizationTokensHolder.read()
    }

    init(
        customerWalletId: String,
        authorizationTokensRepository: PaymentAccountAuthorizationTokensRepository,
        apiType: VisaAPIType,
        apiService: TangemPayAPIService<TangemPayAuthorizationAPITarget>,
        tokens: TangemPayAuthorizationTokens?
    ) {
        self.customerWalletId = customerWalletId
        self.authorizationTokensRepository = authorizationTokensRepository
        self.apiType = apiType
        self.apiService = apiService
        authorizationTokensHolder = ThreadSafeContainer(tokens)
    }

    private func refreshTokenIfNeeded() async throws(TangemPayAPIServiceError) {
        guard let tokens, !tokens.refreshTokenExpired else {
            throw .unauthorized
        }

        if tokens.accessTokenExpired {
            let newTokens = try await refreshTokens(refreshToken: tokens.refreshToken)
            try? saveTokens(tokens: newTokens)
        }
    }

    private func refreshTokens(refreshToken: String) async throws(TangemPayAPIServiceError) -> TangemPayAuthorizationTokens {
        try await request(for: .refreshTokens(request: .init(refreshToken: refreshToken)))
    }

    private func request<T: Decodable>(for target: TangemPayAuthorizationAPITarget.Target) async throws(TangemPayAPIServiceError) -> T {
        try await apiService.request(
            .init(
                target: target,
                apiType: apiType
            )
        )
    }
}

extension CommonPaymentAccountAuthorizationService: PaymentAccountAuthorizationService {
    func getChallenge(
        customerWalletAddress: String,
        customerWalletId: String
    ) async throws(TangemPayAPIServiceError) -> TangemPayGetChallengeResponse {
        try await request(for: .getChallenge(.init(
            customerWalletAddress: customerWalletAddress,
            customerWalletId: customerWalletId
        )))
    }

    func getTokens(
        sessionId: String,
        signedChallenge: String,
        messageFormat: String
    ) async throws(TangemPayAPIServiceError) -> TangemPayAuthorizationTokens {
        try await request(for: .getTokens(
            .init(
                signature: signedChallenge,
                sessionId: sessionId,
                messageFormat: messageFormat
            ))
        )
    }
}

extension CommonPaymentAccountAuthorizationService: PaymentAccountAuthorizationTokensHandler {
    var authorizationHeader: String? {
        guard let tokens else {
            return nil
        }
        return "Bearer " + tokens.accessToken
    }

    func saveTokens(tokens: TangemPayAuthorizationTokens) throws {
        authorizationTokensHolder.mutate {
            $0 = tokens
        }

        try authorizationTokensRepository.save(tokens: tokens, customerWalletId: customerWalletId)
    }

    func prepare() async throws(TangemPayAPIServiceError) {
        try await taskProcessor.execute { [weak self] () async throws(TangemPayAPIServiceError) in
            try await self?.refreshTokenIfNeeded()
        }
    }
}
