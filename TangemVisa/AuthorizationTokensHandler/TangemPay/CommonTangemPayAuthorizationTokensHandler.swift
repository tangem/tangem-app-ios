//
//  CommonTangemPayAuthorizationTokensHandler.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation

public enum TangemPayApiErrorEvent {
    case unauthorized
    case other
}

final class CommonTangemPayAuthorizationTokensHandler {
    private let customerWalletId: String
    private let authorizationService: TangemPayAuthorizationService
    private let authorizationTokensRepository: TangemPayAuthorizationTokensRepository

    private let authorizationTokensHolder: ThreadSafeContainer<TangemPayAuthorizationTokens?>
    private let taskProcessor = SingleTaskProcessor<Void, Error>()
    private let errorEventSubject = PassthroughSubject<TangemPayApiErrorEvent, Never>()

    private var tokens: TangemPayAuthorizationTokens? {
        authorizationTokensHolder.read()
    }

    init(
        customerWalletId: String,
        tokens: TangemPayAuthorizationTokens?,
        authorizationService: TangemPayAuthorizationService,
        authorizationTokensRepository: TangemPayAuthorizationTokensRepository
    ) {
        self.customerWalletId = customerWalletId
        authorizationTokensHolder = ThreadSafeContainer(tokens)
        self.authorizationService = authorizationService
        self.authorizationTokensRepository = authorizationTokensRepository
    }

    private func refreshTokenIfNeeded() async throws {
        guard let tokens, !tokens.refreshTokenExpired else {
            errorEventSubject.send(.unauthorized)
            // [REDACTED_TODO_COMMENT]
            throw VisaAuthorizationTokensHandlerError.refreshTokenExpired
        }

        if tokens.accessTokenExpired {
            do {
                let newTokens = try await authorizationService.refreshTokens(refreshToken: tokens.refreshToken)
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

extension CommonTangemPayAuthorizationTokensHandler: TangemPayAuthorizationTokensHandler {
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
