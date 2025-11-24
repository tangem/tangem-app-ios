//
//  CommonTangemPayAuthorizationTokensHandler.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemFoundation

final class CommonTangemPayAuthorizationTokensHandler {
    weak var authorizationTokensSaver: TangemPayAuthorizationTokensSaver?

    private let customerWalletId: String
    private let authorizationService: TangemPayAuthorizationService
    private let authorizationTokensHolder = ThreadSafeContainer<TangemPayAuthorizationTokens?>(nil)

    init(
        customerWalletId: String,
        authorizationService: TangemPayAuthorizationService
    ) {
        self.customerWalletId = customerWalletId
        self.authorizationService = authorizationService
    }
}

extension CommonTangemPayAuthorizationTokensHandler: TangemPayAuthorizationTokensHandler {
    var accessTokenExpired: Bool {
        authorizationTokensHolder.read()?.accessTokenExpired ?? true
    }

    var refreshTokenExpired: Bool {
        authorizationTokensHolder.read()?.refreshTokenExpired ?? true
    }

    var authorizationHeader: String? {
        guard let tokens = authorizationTokensHolder.read() else {
            return nil
        }
        return AuthorizationTokensUtility.getAuthorizationHeader(from: tokens)
    }

    func saveTokens(tokens: TangemPayAuthorizationTokens) throws {
        authorizationTokensHolder.mutate {
            $0 = tokens
        }

        try authorizationTokensSaver?.saveAuthorizationTokensToStorage(
            tokens: tokens,
            customerWalletId: customerWalletId
        )
    }

    func refreshTokens() async throws {
        guard let tokens = authorizationTokensHolder.read() else {
            return
        }

        if tokens.refreshTokenExpired {
            throw VisaAuthorizationTokensHandlerError.refreshTokenExpired
        }

        let newTokens = try await authorizationService.refreshTokens(refreshToken: tokens.refreshToken)

        if newTokens.accessTokenExpired {
            throw VisaAuthorizationTokensHandlerError.failedToUpdateAccessToken
        }

        try saveTokens(tokens: newTokens)
    }
}
