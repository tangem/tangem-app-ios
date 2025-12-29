//
//  CommonTangemPayAuthorizationService.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation
import TangemSdk

final class CommonTangemPayAuthorizationService {
    private let customerWalletId: String
    private let authorizationTokensRepository: TangemPayAuthorizationTokensRepository

    private let apiType: VisaAPIType
    private let apiService: TangemPayAPIService<TangemPayAuthorizationAPITarget>

    private let authorizationTokensHolder: ThreadSafeContainer<TangemPayAuthorizationTokens?>
    private let taskProcessor = SingleTaskProcessor<Void, Error>()
    private let errorEventSubject = PassthroughSubject<TangemPayApiErrorEvent, Never>()

    private var tokens: TangemPayAuthorizationTokens? {
        authorizationTokensHolder.read()
    }

    init(
        customerWalletId: String,
        authorizationTokensRepository: TangemPayAuthorizationTokensRepository,
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

    private func refreshTokenIfNeeded() async throws {
        guard let tokens, !tokens.refreshTokenExpired else {
            errorEventSubject.send(.unauthorized)
            // [REDACTED_TODO_COMMENT]
            throw VisaAuthorizationTokensHandlerError.refreshTokenExpired
        }

        if tokens.accessTokenExpired {
            do {
                let newTokens = try await refreshTokens(refreshToken: tokens.refreshToken)
                try? saveTokens(tokens: newTokens)
            } catch .apiError(let errorWithStatusCode) where errorWithStatusCode.statusCode == 401 {
                VisaLogger.error("Failed to refresh token", error: errorWithStatusCode.error)
                errorEventSubject.send(.unauthorized)
                throw errorWithStatusCode.error
            } catch {
                VisaLogger.error("Failed to refresh token", error: error)
                errorEventSubject.send(.other)
                throw error.underlyingError
            }
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
            wrapped: false
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
            wrapped: false
        )
    }

    func refreshTokens(refreshToken: String) async throws(TangemPayAPIServiceError) -> TangemPayAuthorizationTokens {
        try await apiService.request(
            .init(
                target: .refreshTokens(.init(refreshToken: refreshToken)),
                apiType: apiType
            ),
            wrapped: false
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
        return AuthorizationTokensUtility.getAuthorizationHeader(from: tokens)
    }

    var errorEventPublisher: AnyPublisher<TangemPayApiErrorEvent, Never> {
        errorEventSubject.eraseToAnyPublisher()
    }

    func saveTokens(tokens: TangemPayAuthorizationTokens) throws {
        authorizationTokensHolder.mutate {
            $0 = tokens
        }

        try authorizationTokensRepository.save(tokens: tokens, customerWalletId: customerWalletId)
    }

    func prepare() async throws {
        try await taskProcessor.execute { [weak self] in
            try await self?.refreshTokenIfNeeded()
        }
    }
}
