//
//  CommonTangemPayAuthorizationTokensHandler.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemFoundation

public enum TangemPayAuthorizationTokensHandlerError: Error {
    case unauthorized
    case otherError(Error)
}

final class CommonTangemPayAuthorizationTokensHandler {
    private let customerWalletId: String
    private let authorizationService: TangemPayAuthorizationService
    private let authorizationTokensRepository: TangemPayAuthorizationTokensRepository

    private let authorizationTokensHolder: ThreadSafeContainer<TangemPayAuthorizationTokens?>
    private let taskProcessor = SingleTaskProcessor<Void, Error>()

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

    private func refreshTokenIfNeeded() async throws(TangemPayAuthorizationTokensHandlerError) {
        guard let tokens else {
            throw .unauthorized
        }

        if tokens.refreshTokenExpired {
            throw .unauthorized
        }

        if tokens.accessTokenExpired {
            let newTokensResult = await authorizationService.refreshTokens(refreshToken: tokens.refreshToken)

            switch newTokensResult {
            case .success(let value):
                try? saveTokens(tokens: value)

            case .failure(.apiError(let errorWithStatusCode)) where errorWithStatusCode.statusCode == 401:
                VisaLogger.error("Failed to refresh token", error: errorWithStatusCode.error)
                throw .unauthorized

            case .failure(let error):
                VisaLogger.error("Failed to refresh token", error: error)
                throw .otherError(error)
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
            throw .otherError(error)
        }
    }
}
