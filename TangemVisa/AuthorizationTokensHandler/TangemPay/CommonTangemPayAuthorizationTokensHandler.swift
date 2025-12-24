//
//  CommonTangemPayAuthorizationTokensHandler.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemFoundation

public enum TangemPayAuthorizationTokensHandlerError: Error {
    case syncNeeded
    case unavailable(Error)
}

final class CommonTangemPayAuthorizationTokensHandler {
    private let customerWalletId: String
    private let authorizationService: TangemPayAuthorizationService
    private let authorizationTokensRepository: TangemPayAuthorizationTokensRepository

    private let authorizationTokensHolder: ThreadSafeContainer<TangemPayAuthorizationTokens?>
    private let taskProcessor = SingleTaskProcessor<Void, Error>()

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

    private func refreshTokenIfNeeded() async throws(TangemPayAuthorizationTokensHandlerError) {
        guard let tokens else {
            throw .syncNeeded
        }

        if tokens.refreshTokenExpired {
            throw .syncNeeded
        }

        if tokens.accessTokenExpired {
            let newTokensResult = await authorizationService.refreshTokens(refreshToken: tokens.refreshToken)

            switch newTokensResult {
            case .success(let value):
                try? saveTokens(tokens: value)

            case .failure(.apiError(let errorWithStatusCode)) where errorWithStatusCode.statusCode == 401:
                VisaLogger.error("Failed to refresh token", error: errorWithStatusCode.error)
                throw .syncNeeded

            case .failure(let error):
                VisaLogger.error("Failed to refresh token", error: error)
                throw .unavailable(error)
            }
        }
    }
}

extension CommonTangemPayAuthorizationTokensHandler: TangemPayAuthorizationTokensHandler {
    var tokens: TangemPayAuthorizationTokens? {
        authorizationTokensHolder.read()
    }

    var authorizationHeader: String? {
        guard let tokens else {
            return nil
        }
        return AuthorizationTokensUtility.getAuthorizationHeader(from: tokens)
    }

    func saveTokens(tokens: TangemPayAuthorizationTokens) throws {
        authorizationTokensHolder.mutate {
            $0 = tokens
        }

        try authorizationTokensRepository.save(tokens: tokens, customerWalletId: customerWalletId)
    }

    func prepare() async throws(TangemPayAuthorizationTokensHandlerError) {
        do {
            try await taskProcessor.execute { [weak self] in
                try await self?.refreshTokenIfNeeded()
            }
        } catch let error as TangemPayAuthorizationTokensHandlerError {
            throw error
        } catch {
            throw .unavailable(error)
        }
    }
}
