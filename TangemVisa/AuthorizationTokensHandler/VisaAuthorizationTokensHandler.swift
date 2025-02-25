//
//  VisaAuthorizationTokensHandler.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation
import JWTDecode

public protocol VisaRefreshTokenSaver: AnyObject {
    func saveRefreshTokenToStorage(refreshToken: String, cardId: String) throws
}

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

class CommonVisaAuthorizationTokensHandler {
    private let tokenRefreshService: VisaAuthorizationTokenRefreshService
    private weak var refreshTokenSaver: VisaRefreshTokenSaver?

    private let cardId: String
    private let scheduler: AsyncTaskScheduler = .init()
    private let logger = InternalLogger(tag: .authorizationTokenHandler)

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
        logger.info("Setup refresher task. Current refresher task is nil: \(refresherTask == nil)")
        refresherTask?.cancel()
        refresherTask = Task { [weak self] in
            do {
                guard await self?.authorizationTokensHolder.authorizationTokens != nil else {
                    return
                }

                try await self?.setupAccessTokenRefresher()
            } catch {
                if error is CancellationError {
                    self?.logger.info("Refresher task was cancelled")
                    return
                }
                self?.logger.error("Failed to update access token", error: error)
            }
        }.eraseToAnyCancellable()
    }

    private func setupAccessTokenRefresher() async throws {
        logger.info("Attempting to setup token refresher")
        guard let jwtTokens = await authorizationTokensHolder.tokens else {
            throw VisaAuthorizationTokensHandlerError.authorizationTokensNotFound
        }

        logger.info("JWT tokens found. Checking expiration date.")
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
            logger.info("Access token needs to be refreshed.")
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
                self?.logger.info("Failed to find access token. Canceling scheduled refresh job.")
                self?.scheduler.cancel()
                return
            }

            do {
                try await self?.refreshAccessToken(refreshJWTToken: jwtTokens.refreshToken)
            } catch {
                self?.logger.error("Failed to refresh access token", error: error)
            }
        }
    }

    @discardableResult
    private func refreshAccessToken(refreshJWTToken: JWT) async throws -> DecodedAuthorizationJWTTokens {
        logger.info("Refreshing access token")
        if refreshJWTToken.expired {
            logger.info("Refresh token expired, cant refresh")
            throw VisaAuthorizationTokensHandlerError.refreshTokenExpired
        }

        let visaTokens = try await tokenRefreshService.refreshAccessToken(refreshToken: refreshJWTToken.string)
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
        logger.info("Setup new authorization tokens in token handler")
        try await authorizationTokensHolder.setTokens(authorizationTokens: tokens)
        /// We need to use `setupRefresherTask` to prevent blocking current task
        setupRefresherTask()
    }

    func forceRefreshToken() async throws {
        guard let tokens = await authorizationTokensHolder.tokens else {
            logger.info("Nothing to refresh")
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
                    handler.logger.info("Nothing to save in refresh token storage")
                    return
                }

                try refreshTokenSaver.saveRefreshTokenToStorage(
                    refreshToken: tokens.refreshToken.string,
                    cardId: handler.cardId
                )
            } catch {
                handler.logger.error("Failed to save refresh token after saver setup", error: error)
            }
        }
    }
}
