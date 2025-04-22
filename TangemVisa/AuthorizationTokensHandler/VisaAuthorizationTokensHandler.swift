//
//  VisaAuthorizationTokensHandler.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import LocalAuthentication
import Combine
import TangemFoundation
import JWTDecode

/// A protocol defining an interface to persist a Visa refresh token to storage.
/// Used to save the refresh token locally in a secure  manner.
public protocol VisaRefreshTokenSaver: AnyObject {
    func saveRefreshTokenToStorage(refreshToken: String, cardId: String) throws
}

/// A protocol that extends `VisaRefreshTokenSaver` with full CRUD operations for Visa refresh tokens.
/// Also handles secure and biometric storage and memory persistence.
public protocol VisaRefreshTokenRepository: VisaRefreshTokenSaver {
    func save(refreshToken: String, cardId: String) throws
    func deleteToken(cardId: String) throws
    /// - Parameters:
    ///  - cardIdTokenToKeep: this token will be saved after clearing secure and biometrics storages, but it will only persist in memory, not in storages
    func clear(cardIdTokenToKeep: String?)
    func fetch(using context: LAContext)
    func getToken(forCardId cardId: String) -> String?
    func lock()
}

public extension VisaRefreshTokenRepository {
    func clear() {
        clear(cardIdTokenToKeep: nil)
    }
}

public extension VisaRefreshTokenRepository {
    func saveRefreshTokenToStorage(refreshToken: String, cardId: String) throws {
        try save(refreshToken: refreshToken, cardId: cardId)
    }
}

/// A protocol for managing Visa access and refresh tokens, including automatic refresh,
/// persistence, and exposure of authorization headers.
/// Implementations must ensure safe token lifecycle handling and validity checking.
public protocol VisaAuthorizationTokensHandler {
    var accessToken: JWT? { get async }
    var accessTokenExpired: Bool { get async }
    var refreshTokenExpired: Bool { get async }
    var containsAccessToken: Bool { get async }
    var authorizationHeader: String { get async throws }
    var authorizationTokens: VisaAuthorizationTokens? { get async }
    func setupTokens(_ tokens: VisaAuthorizationTokens) async throws
    func forceRefreshToken() async throws
    func setupRefreshTokenSaver(_ refreshTokenSaver: VisaRefreshTokenSaver)
}

/// Handles the lifecycle of Visa authorization tokens including auto-refresh, validation,
/// and integration with secure token saving mechanisms.
///
/// This class uses a background scheduler to refresh access tokens before expiration
/// and exposes access to current authorization headers and tokens.
///
/// - Uses `AuthorizationTokensHolder` actor to store and retrieve tokens.
/// - Uses `VisaAuthorizationTokenRefreshService` to refresh access tokens from a backend.
/// - Optionally uses a `VisaRefreshTokenSaver` to persist the refresh token.
final class CommonVisaAuthorizationTokensHandler {
    private let tokenRefreshService: VisaAuthorizationTokenRefreshService
    private weak var refreshTokenSaver: VisaRefreshTokenSaver?

    private let cardId: String
    private let scheduler: AsyncTaskScheduler = .init()

    private let authorizationTokensHolder: AuthorizationTokensHolder
    private var refresherTask: AnyCancellable?

    private let minSecondsBeforeExpiration: TimeInterval = 60.0

    init(
        cardId: String,
        authorizationTokensHolder: AuthorizationTokensHolder,
        tokenRefreshService: VisaAuthorizationTokenRefreshService,
        refreshTokenSaver: VisaRefreshTokenSaver?
    ) {
        self.cardId = cardId
        self.authorizationTokensHolder = authorizationTokensHolder
        self.tokenRefreshService = tokenRefreshService
        self.refreshTokenSaver = refreshTokenSaver

        setupRefresherTask()
    }

    private func setupRefresherTask() {
        VisaLogger.info("Setup refresher task. Current refresher task is nil: \(refresherTask == nil)")
        refresherTask?.cancel()
        refresherTask = Task { [weak self] in
            do {
                guard await self?.authorizationTokensHolder.authorizationTokens != nil else {
                    return
                }

                try await self?.setupAccessTokenRefresher()
            } catch {
                if error is CancellationError {
                    VisaLogger.info("Refresher task was cancelled")
                    return
                }
                VisaLogger.error("Failed to update access token", error: error)
            }
        }.eraseToAnyCancellable()
    }

    private func setupAccessTokenRefresher() async throws {
        VisaLogger.info("Attempting to setup token refresher")
        guard let jwtTokens = await authorizationTokensHolder.tokens else {
            throw VisaAuthorizationTokensHandlerError.authorizationTokensNotFound
        }

        VisaLogger.info("JWT tokens found. Checking expiration date.")
        guard
            let accessToken = jwtTokens.accessToken,
            let expirationDate = accessToken.expiresAt,
            let issuedAtDate = accessToken.issuedAt
        else {
            throw VisaAuthorizationTokensHandlerError.missingMandatoryInfoInAccessToken
        }

        let now = Date()
        let timeBeforeExpiration = expirationDate.timeIntervalSince(now)
        let shouldRefreshToken = timeBeforeExpiration < minSecondsBeforeExpiration || accessToken.expired

        // We need to refresh token before setup token update with fixed interval
        if shouldRefreshToken {
            VisaLogger.info("Access token needs to be refreshed.")
            // Token already expired or will expire very soon. Refreshing
            try await refreshAccessToken(refreshJWTToken: jwtTokens.refreshToken)
        } else {
            let maxDateBeforeUpdate = Calendar.current.date(
                byAdding: .second,
                value: -Int(minSecondsBeforeExpiration),
                to: expirationDate
            ) ?? now
            let refreshDelay = maxDateBeforeUpdate.timeIntervalSince(now)

            // Wait until token will need to refresh and update it one time
            try await Task.sleep(seconds: refreshDelay)
            try await refreshAccessToken(refreshJWTToken: jwtTokens.refreshToken)
        }

        try Task.checkCancellation()
        // Setup recurring token update with fixed interval
        let tokenLifeTime = expirationDate.timeIntervalSince(issuedAtDate)
        let tokenRefreshTimeInterval = tokenLifeTime - minSecondsBeforeExpiration
        scheduler.scheduleJob(interval: tokenRefreshTimeInterval, repeats: true) { [weak self] in
            guard let jwtTokens = await self?.authorizationTokensHolder.tokens else {
                VisaLogger.info("Failed to find access token. Canceling scheduled refresh job.")
                self?.scheduler.cancel()
                return
            }

            do {
                try await self?.refreshAccessToken(refreshJWTToken: jwtTokens.refreshToken)
            } catch {
                VisaLogger.error("Failed to refresh access token", error: error)
            }
        }
    }

    @discardableResult
    private func refreshAccessToken(refreshJWTToken: JWT) async throws -> DecodedAuthorizationJWTTokens {
        VisaLogger.info("Refreshing access token")
        if refreshJWTToken.expired {
            VisaLogger.info("Refresh token expired, cant refresh")
            throw VisaAuthorizationTokensHandlerError.refreshTokenExpired
        }

        guard let authorizationType = await authorizationTokensHolder.authorizationTokens?.authorizationType else {
            throw VisaAuthorizationTokensHandlerError.refreshTokenExpired
        }

        let visaTokens = try await tokenRefreshService.refreshAccessToken(
            refreshToken: refreshJWTToken.string,
            authorizationType: authorizationType
        )
        let newJWTTokens = try AuthorizationTokensUtility().decodeAuthTokens(visaTokens)

        guard let accessToken = newJWTTokens.accessToken else {
            throw VisaAuthorizationTokensHandlerError.missingAccessToken
        }

        if accessToken.expired {
            throw VisaAuthorizationTokensHandlerError.failedToUpdateAccessToken
        }

        await authorizationTokensHolder.setTokens(newJWTTokens)
        try refreshTokenSaver?.saveRefreshTokenToStorage(refreshToken: newJWTTokens.refreshToken.string, cardId: cardId)
        return newJWTTokens
    }
}

extension CommonVisaAuthorizationTokensHandler: VisaAuthorizationTokensHandler {
    var accessToken: JWT? {
        get async { await authorizationTokensHolder.tokens?.accessToken }
    }

    var accessTokenExpired: Bool {
        get async { await authorizationTokensHolder.tokens?.accessToken?.expired ?? true }
    }

    var refreshTokenExpired: Bool {
        get async { await authorizationTokensHolder.tokens?.refreshToken.expired ?? true }
    }

    var containsAccessToken: Bool {
        get async { await authorizationTokensHolder.tokens != nil }
    }

    var authorizationHeader: String {
        get async throws {
            guard let jwtTokens = await authorizationTokensHolder.tokens else {
                throw VisaAuthorizationTokensHandlerError.missingAccessToken
            }

            return try AuthorizationTokensUtility().getAuthorizationHeader(from: jwtTokens)
        }
    }

    var authorizationTokens: VisaAuthorizationTokens? {
        get async {
            await authorizationTokensHolder.authorizationTokens
        }
    }

    func setupTokens(_ tokens: VisaAuthorizationTokens) async throws {
        VisaLogger.info("Setup new authorization tokens in token handler")
        try await authorizationTokensHolder.setTokens(authorizationTokens: tokens)
        // We need to use `setupRefresherTask` to prevent blocking current task
        setupRefresherTask()
    }

    func forceRefreshToken() async throws {
        guard let tokens = await authorizationTokensHolder.tokens else {
            VisaLogger.info("Nothing to refresh")
            return
        }

        let newTokens = try await refreshAccessToken(refreshJWTToken: tokens.refreshToken)
        setupRefresherTask()
        try refreshTokenSaver?.saveRefreshTokenToStorage(refreshToken: newTokens.refreshToken.string, cardId: cardId)
    }

    func setupRefreshTokenSaver(_ refreshTokenSaver: any VisaRefreshTokenSaver) {
        self.refreshTokenSaver = refreshTokenSaver
        runTask(in: self) { handler in
            do {
                guard let tokens = await handler.authorizationTokensHolder.tokens else {
                    VisaLogger.info("Nothing to save in refresh token storage")
                    return
                }

                try refreshTokenSaver.saveRefreshTokenToStorage(
                    refreshToken: tokens.refreshToken.string,
                    cardId: handler.cardId
                )
            } catch {
                VisaLogger.error("Failed to save refresh token after saver setup", error: error)
            }
        }
    }
}
