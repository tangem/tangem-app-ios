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

public enum VisaRefreshTokenId: RawRepresentable, Hashable {
    private enum Key: String {
        case cardId

        // [REDACTED_TODO_COMMENT]
        // [REDACTED_INFO]
        case customerWalletAddress
    }

    case cardId(String)

    // [REDACTED_TODO_COMMENT]
    // [REDACTED_INFO]
    case customerWalletAddress(String)

    public init?(rawValue: String) {
        let components = rawValue.components(separatedBy: "_")
        guard components.count == 2 else {
            return nil
        }

        switch (components[0], components[1]) {
        case (Key.cardId.rawValue, let cardId):
            self = .cardId(cardId)

        case (Key.customerWalletAddress.rawValue, let customerWalletAddress):
            self = .customerWalletAddress(customerWalletAddress)

        default:
            return nil
        }
    }

    public var rawValue: String {
        switch self {
        case .cardId(let cardId):
            "\(Key.cardId.rawValue)_\(cardId)"

        case .customerWalletAddress(let customerWalletAddress):
            "\(Key.customerWalletAddress.rawValue)_\(customerWalletAddress)"
        }
    }
}

/// A protocol defining an interface to persist a Visa refresh token to storage.
/// Used to save the refresh token locally in a secure  manner.
public protocol VisaRefreshTokenSaver: AnyObject {
    func saveRefreshTokenToStorage(refreshToken: String, visaRefreshTokenId: VisaRefreshTokenId) throws
}

/// A protocol that extends `VisaRefreshTokenSaver` with full CRUD operations for Visa refresh tokens.
/// Also handles secure and biometric storage and memory persistence.
public protocol VisaRefreshTokenRepository: VisaRefreshTokenSaver {
    func save(refreshToken: String, visaRefreshTokenId: VisaRefreshTokenId) throws
    func deleteToken(visaRefreshTokenId: VisaRefreshTokenId) throws
    func clearPersistent()
    func fetch(using context: LAContext)
    func getToken(forVisaRefreshTokenId visaRefreshTokenId: VisaRefreshTokenId) -> String?
    func lock()
}

public extension VisaRefreshTokenRepository {
    func saveRefreshTokenToStorage(refreshToken: String, visaRefreshTokenId: VisaRefreshTokenId) throws {
        try save(refreshToken: refreshToken, visaRefreshTokenId: visaRefreshTokenId)
    }
}

/// A protocol for managing Visa access and refresh tokens, including automatic refresh,
/// persistence, and exposure of authorization headers.
/// Implementations must ensure safe token lifecycle handling and validity checking.
public protocol VisaAuthorizationTokensHandler {
    // [REDACTED_TODO_COMMENT]
    var accessToken: JWT? { get }
    var accessTokenExpired: Bool { get }
    var refreshTokenExpired: Bool { get }
    var containsAccessToken: Bool { get }
    var authorizationHeader: String? { get }
    var authorizationTokens: VisaAuthorizationTokens? { get }
    func setupTokens(_ tokens: VisaAuthorizationTokens) async throws
    func forceRefreshToken() async throws
    func exchageTokens() async throws
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
    private let allowRefresherTask: Bool

    private let visaRefreshTokenId: VisaRefreshTokenId
    private let scheduler: AsyncTaskScheduler = .init()

    private let authorizationTokensHolder: AuthorizationTokensHolder
    private var refresherTask: AnyCancellable?

    private let minSecondsBeforeExpiration: TimeInterval = 60.0

    init(
        visaRefreshTokenId: VisaRefreshTokenId,
        authorizationTokensHolder: AuthorizationTokensHolder,
        tokenRefreshService: VisaAuthorizationTokenRefreshService,
        refreshTokenSaver: VisaRefreshTokenSaver?,
        allowRefresherTask: Bool
    ) {
        self.visaRefreshTokenId = visaRefreshTokenId
        self.authorizationTokensHolder = authorizationTokensHolder
        self.tokenRefreshService = tokenRefreshService
        self.refreshTokenSaver = refreshTokenSaver
        self.allowRefresherTask = allowRefresherTask

        if allowRefresherTask {
            setupRefresherTask()
        }
    }

    private func setupRefresherTask() {
        refresherTask?.cancel()
        scheduler.cancel()
        refresherTask = Task { [weak self] in
            do {
                guard let tokens = self?.authorizationTokensHolder.tokensInfo else {
                    VisaLogger.info("Can't setup authorization tokens refresh task, missing authorization tokens in holder")
                    return
                }

                try await self?.setupAccessTokenRefresher(for: tokens)
            } catch {
                if error is CancellationError {
                    VisaLogger.info("Refresher task was cancelled")
                    return
                }
                VisaLogger.error("Failed to update access token", error: error)
            }
        }.eraseToAnyCancellable()
    }

    private func setupAccessTokenRefresher(for tokens: InternalAuthorizationTokens) async throws {
        VisaLogger.info("Attempting to setup token refresher")

        let jwtTokens = tokens.jwtTokens
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
            try await refreshAccessToken(internalTokens: tokens)
        } else {
            let maxDateBeforeUpdate = Calendar.current.date(
                byAdding: .second,
                value: -Int(minSecondsBeforeExpiration),
                to: expirationDate
            ) ?? now
            let refreshDelay = maxDateBeforeUpdate.timeIntervalSince(now)

            VisaLogger.info("No need to refresh access token, awaits \(refreshDelay) seconds and then confinue setup process")
            // Wait until token will need to refresh and update it one time
            try await Task.sleep(for: .seconds(refreshDelay))
            try await refreshAccessToken(internalTokens: tokens)
        }

        try Task.checkCancellation()
        // Setup recurring token update with fixed interval
        let tokenLifeTime = expirationDate.timeIntervalSince(issuedAtDate)
        let tokenRefreshTimeInterval = tokenLifeTime - minSecondsBeforeExpiration
        VisaLogger.info("Scheduling token refresh each: \(tokenRefreshTimeInterval) seconds.")
        scheduler.scheduleJob(interval: tokenRefreshTimeInterval, repeats: true) { [weak self] in
            guard let tokens = self?.authorizationTokensHolder.tokensInfo else {
                VisaLogger.info("Failed to find access token. Canceling scheduled refresh job.")
                self?.scheduler.cancel()
                return
            }

            do {
                try await self?.refreshAccessToken(internalTokens: tokens)
            } catch {
                VisaLogger.error("Failed to refresh access token", error: error)
            }
        }
    }

    private func refreshAccessToken(internalTokens: InternalAuthorizationTokens, file: String = #file, line: Int = #line) async throws {
        let refreshJWTToken = internalTokens.jwtTokens.refreshToken
        VisaLogger.info("Refreshing access token from \(file):\(line)")
        if refreshJWTToken.expired {
            VisaLogger.info("Refresh token expired, cant refresh")
            throw VisaAuthorizationTokensHandlerError.refreshTokenExpired
        }

        let visaTokens = try await tokenRefreshService.refreshAccessToken(
            refreshToken: refreshJWTToken.string,
            authorizationType: internalTokens.bffTokens.authorizationType
        )
        let newTokens = try InternalAuthorizationTokens(bffTokens: visaTokens)

        guard let newAccessToken = newTokens.jwtTokens.accessToken else {
            VisaLogger.error("While refreshing tokens missing access token", error: VisaAuthorizationTokensHandlerError.missingAccessToken)
            throw VisaAuthorizationTokensHandlerError.missingAccessToken
        }

        if newAccessToken.expired {
            VisaLogger.error("New received access token is expired...", error: VisaAuthorizationTokensHandlerError.failedToUpdateAccessToken)
            throw VisaAuthorizationTokensHandlerError.failedToUpdateAccessToken
        }

        try await saveTokens(authTokens: newTokens)
    }

    private func exchangeTokens(internalTokens: InternalAuthorizationTokens, file: String = #file, line: Int = #line) async throws {
        let cardActivationTokens = internalTokens.bffTokens
        let refreshToken = cardActivationTokens.refreshToken

        guard let accessToken = cardActivationTokens.accessToken else {
            throw VisaAuthorizationTokensHandlerError.missingAccessToken
        }

        let activatedCardTokens = try await tokenRefreshService.exchangeTokens(
            accessToken: accessToken,
            refreshToken: refreshToken,
            authorizationType: cardActivationTokens.authorizationType
        )

        let newTokens = try InternalAuthorizationTokens(bffTokens: activatedCardTokens)

        guard let newAccessToken = newTokens.jwtTokens.accessToken else {
            VisaLogger.error("While refreshing tokens missing access token", error: VisaAuthorizationTokensHandlerError.missingAccessToken)
            throw VisaAuthorizationTokensHandlerError.missingAccessToken
        }

        if newAccessToken.expired {
            VisaLogger.error("New received access token is expired...", error: VisaAuthorizationTokensHandlerError.failedToUpdateAccessToken)
            throw VisaAuthorizationTokensHandlerError.failedToUpdateAccessToken
        }

        try await saveTokens(authTokens: newTokens)
    }

    private func saveTokens(tokens: VisaAuthorizationTokens) async throws {
        let authTokens = try InternalAuthorizationTokens(bffTokens: tokens)
        try await saveTokens(authTokens: authTokens)
    }

    private func saveTokens(authTokens: InternalAuthorizationTokens) async throws {
        try await authorizationTokensHolder.setTokens(authorizationTokens: authTokens)

        switch authTokens.bffTokens.authorizationType {
        case .cardWallet, .customerWallet:
            break
        case .cardId:
            return
        }

        try refreshTokenSaver?.saveRefreshTokenToStorage(refreshToken: authTokens.bffTokens.refreshToken, visaRefreshTokenId: visaRefreshTokenId)
    }
}

extension CommonVisaAuthorizationTokensHandler: VisaAuthorizationTokensHandler {
    var accessToken: JWT? { authorizationTokensHolder.tokensInfo?.jwtTokens.accessToken }

    var accessTokenExpired: Bool { authorizationTokensHolder.tokensInfo?.jwtTokens.accessToken?.expired ?? true }

    var refreshTokenExpired: Bool { authorizationTokensHolder.tokensInfo?.jwtTokens.refreshToken.expired ?? true }

    var containsAccessToken: Bool { authorizationTokensHolder.tokensInfo != nil }

    var authorizationHeader: String? {
        do {
            guard let tokens = authorizationTokensHolder.tokensInfo else {
                throw VisaAuthorizationTokensHandlerError.missingAccessToken
            }

            return try AuthorizationTokensUtility().getAuthorizationHeader(from: tokens.jwtTokens)
        } catch {
            return nil
        }
    }

    var authorizationTokens: VisaAuthorizationTokens? {
        authorizationTokensHolder.tokensInfo?.bffTokens
    }

    func setupTokens(_ tokens: VisaAuthorizationTokens) async throws {
        VisaLogger.info("Setup new authorization tokens in token handler")
        try await saveTokens(tokens: tokens)

        if allowRefresherTask {
            // We need to use `setupRefresherTask` to prevent blocking current task
            setupRefresherTask()
        }
    }

    func forceRefreshToken() async throws {
        guard let tokens = authorizationTokensHolder.tokensInfo else {
            VisaLogger.info("Nothing to refresh")
            return
        }

        try await refreshAccessToken(internalTokens: tokens)

        if allowRefresherTask {
            setupRefresherTask()
        }
    }

    func exchageTokens() async throws {
        guard let tokens = authorizationTokensHolder.tokensInfo else {
            VisaLogger.info("Nothing to exchange")
            return
        }

        try await exchangeTokens(internalTokens: tokens)
    }

    func setupRefreshTokenSaver(_ refreshTokenSaver: any VisaRefreshTokenSaver) {
        self.refreshTokenSaver = refreshTokenSaver
        runTask(in: self) { handler in
            do {
                guard let tokens = handler.authorizationTokensHolder.tokensInfo else {
                    VisaLogger.info("Nothing to save in refresh token storage")
                    return
                }

                try refreshTokenSaver.saveRefreshTokenToStorage(
                    refreshToken: tokens.bffTokens.refreshToken,
                    visaRefreshTokenId: handler.visaRefreshTokenId
                )
            } catch {
                VisaLogger.error("Failed to save refresh token after saver setup", error: error)
            }
        }
    }
}
