//
//  CommonTangemPayAuthorizationTokensHandler.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemFoundation

public protocol TangemPayAuthorizationTokensSaver: AnyObject {
    func saveAuthorizationTokensToStorage(tokens: TangemPayAuthorizationTokens, customerWalletId: String) throws
}

public protocol TangemPayAuthorizationTokensHandler: AnyObject {
    var accessTokenExpired: Bool { get }
    var refreshTokenExpired: Bool { get }
    var authorizationHeader: String? { get }
    var authorizationTokens: TangemPayAuthorizationTokens? { get }

    var authorizationTokensSaver: TangemPayAuthorizationTokensSaver? { get set }

    func setupTokens(_ tokens: TangemPayAuthorizationTokens) async throws
    func forceRefreshToken() async throws
}

final class CommonTangemPayAuthorizationTokensHandler {
    private let customerWalletId: String
    private let authorizationTokensHolder: ThreadSafeContainer<TangemPayAuthorizationTokens?>
    private let authorizationService: TangemPayAuthorizationService

    weak var authorizationTokensSaver: TangemPayAuthorizationTokensSaver?

    init(
        customerWalletId: String,
        tokens: TangemPayAuthorizationTokens?,
        authorizationService: TangemPayAuthorizationService
    ) {
        self.customerWalletId = customerWalletId
        authorizationTokensHolder = .init(tokens)
        self.authorizationService = authorizationService
    }

    private func refreshTokens(
        tokens: TangemPayAuthorizationTokens,
        file: String = #file,
        line: Int = #line
    ) async throws {
        if tokens.refreshTokenExpired {
            VisaLogger.info("Refresh token expired, cant refresh")
            throw VisaAuthorizationTokensHandlerError.refreshTokenExpired
        }

        let newTokens = try await authorizationService.refreshTokens(refreshToken: tokens.refreshToken)

        if newTokens.accessTokenExpired {
            VisaLogger.error("New received access token is expired...", error: VisaAuthorizationTokensHandlerError.failedToUpdateAccessToken)
            throw VisaAuthorizationTokensHandlerError.failedToUpdateAccessToken
        }

        try await saveTokens(tokens: newTokens)
    }

    private func saveTokens(tokens: TangemPayAuthorizationTokens) async throws {
        authorizationTokensHolder.mutate {
            $0 = tokens
        }

        try authorizationTokensSaver?.saveAuthorizationTokensToStorage(
            tokens: tokens,
            customerWalletId: customerWalletId
        )
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

    var authorizationTokens: TangemPayAuthorizationTokens? {
        authorizationTokensHolder.read()
    }

    func setupTokens(_ tokens: TangemPayAuthorizationTokens) async throws {
        try await saveTokens(tokens: tokens)
    }

    func forceRefreshToken() async throws {
        guard let tokens = authorizationTokensHolder.read() else {
            return
        }

        try await refreshTokens(tokens: tokens)
    }
}
