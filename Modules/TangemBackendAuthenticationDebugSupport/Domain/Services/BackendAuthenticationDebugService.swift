//
//  BackendAuthenticationDebugService.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemBackendAuthentication

struct BackendAuthenticationDebugService: Sendable {
    private let dependencies: BackendAuthenticationDebugDependencies
    private let dateProvider: @Sendable () -> Date

    init(
        dependencies: BackendAuthenticationDebugDependencies,
        dateProvider: @escaping @Sendable @autoclosure () -> Date
    ) {
        self.dependencies = dependencies
        self.dateProvider = dateProvider
    }

    var isDeviceRegistered: Bool {
        dependencies.deviceRegistrationStatusRepository.retrieve()
    }

    func devicePublicKey() async throws(DeviceKeyManagerError) -> DevicePublicKey {
        try await dependencies.deviceKeyManager.publicKey
    }

    func sessionTokens() async throws(SessionTokensRepositoryError) -> SessionTokens? {
        try await dependencies.sessionTokensRepository.retrieve()
    }

    @discardableResult
    func renewSessionTokens() async throws -> SessionTokens {
        try await dependencies.renewSessionTokens()
    }

    func resetDeviceRegistration() async throws(SessionTokensRepositoryError) {
        dependencies.deviceRegistrationStatusRepository.persist(isRegistered: false)
        try await dependencies.sessionTokensRepository.delete()
    }

    @discardableResult
    func corruptAccessToken() async throws(SessionTokensRepositoryError) -> SessionTokens? {
        try await updateAccessToken { accessToken in
            SessionTokens.Token(jwt: "", expiresAt: accessToken.expiresAt)
        }
    }

    @discardableResult
    func expireAccessToken() async throws(SessionTokensRepositoryError) -> SessionTokens? {
        try await setAccessTokenExpiration(to: dateProvider().addingTimeInterval(-Constants.expiredAccessTokenAge))
    }

    @discardableResult
    func setAccessTokenExpiration(to expiresAt: Date) async throws(SessionTokensRepositoryError) -> SessionTokens? {
        try await updateAccessToken { accessToken in
            SessionTokens.Token(jwt: accessToken.jwt, expiresAt: expiresAt)
        }
    }

    func clearSessionTokens() async throws(SessionTokensRepositoryError) {
        try await dependencies.sessionTokensRepository.delete()
    }

    private func updateAccessToken(
        _ transform: (SessionTokens.Token) -> SessionTokens.Token
    ) async throws(SessionTokensRepositoryError) -> SessionTokens? {
        guard let sessionTokens = try await dependencies.sessionTokensRepository.retrieve() else {
            return nil
        }

        let updatedSessionTokens = SessionTokens(
            accessToken: transform(sessionTokens.accessToken),
            refreshToken: sessionTokens.refreshToken,
            userWalletIDs: sessionTokens.userWalletIDs
        )
        try await dependencies.sessionTokensRepository.persist(tokens: updatedSessionTokens)

        return updatedSessionTokens
    }
}

// MARK: - Constants

private extension BackendAuthenticationDebugService {
    enum Constants {
        /// How far into the past ``expireAccessToken()`` moves the access token's expiry, so that it's treated as expired. 24h for now.
        static let expiredAccessTokenAge: TimeInterval = 24 * 60 * 60
    }
}
