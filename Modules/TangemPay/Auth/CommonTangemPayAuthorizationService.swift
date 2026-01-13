//
//  CommonTangemPayAuthorizationService.swift
//  TangemPay
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation

final class CommonTangemPayAuthorizationService {
    private let customerWalletId: String
    private let authorizationTokensRepository: TangemPayAuthorizationTokensRepository

    private let apiType: TangemPayAPIType
    private let apiService: TangemPayAPIService<TangemPayAuthorizationAPITarget>

    private let authorizationTokensHolder: ThreadSafeContainer<TangemPayAuthorizationTokens?>
    private let taskProcessor = SingleTaskProcessor<Void, TangemPayAPIServiceError>()

    private var tokens: TangemPayAuthorizationTokens? {
        authorizationTokensHolder.read()
    }

    init(
        customerWalletId: String,
        authorizationTokensRepository: TangemPayAuthorizationTokensRepository,
        apiType: TangemPayAPIType,
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
}

extension CommonTangemPayAuthorizationService: TangemPayAuthorizationService {
    func getChallenge(
        customerWalletAddress: String,
        customerWalletId: String
    ) async throws -> TangemPayGetChallengeResponse {
        try await apiService.request(
            .init(
                target: .getChallenge(.init(
                    customerWalletAddress: customerWalletAddress,
                    customerWalletId: customerWalletId
                )),
                apiType: apiType
            ),
            format: .plain
        )
    }

    func getTokens(
        sessionId: String,
        signedChallenge: String,
        messageFormat: String
    ) async throws -> TangemPayAuthorizationTokens {
        try await apiService.request(
            .init(
                target: .getTokens(
                    .init(
                        signature: signedChallenge,
                        sessionId: sessionId,
                        messageFormat: messageFormat
                    )),
                apiType: apiType
            ),
            format: .plain
        )
    }

    func refreshTokens(refreshToken: String) async throws(TangemPayAPIServiceError) -> TangemPayAuthorizationTokens {
        try await apiService.request(
            .init(
                target: .refreshTokens(.init(refreshToken: refreshToken)),
                apiType: apiType
            ),
            format: .plain
        )
    }
}

extension CommonTangemPayAuthorizationService: TangemPayAuthorizationTokensHandler {
    var refreshTokenExpired: Bool {
        tokens?.refreshTokenExpired ?? true
    }

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
