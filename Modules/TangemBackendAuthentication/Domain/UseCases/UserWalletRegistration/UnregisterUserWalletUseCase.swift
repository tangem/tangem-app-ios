//
//  UnregisterUserWalletUseCase.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public import struct TangemFoundation.UserWalletId

public struct UnregisterUserWalletUseCase: Sendable {
    private let registrationClient: any UserWalletRegistrationClient
    private let registrationStatusRepository: any UserWalletRegistrationStatusRepository
    private let sessionTokensRepository: any SessionTokensRepository

    init(
        registrationClient: some UserWalletRegistrationClient,
        registrationStatusRepository: some UserWalletRegistrationStatusRepository,
        sessionTokensRepository: some SessionTokensRepository
    ) {
        self.registrationClient = registrationClient
        self.registrationStatusRepository = registrationStatusRepository
        self.sessionTokensRepository = sessionTokensRepository
    }

    public func callAsFunction(
        id: UserWalletId,
        shouldEraseSocialLoginData: Bool
    ) async throws(UnregisterUserWalletError) {
        let sessionTokens = try await unregisterUserWallet(id: id, shouldEraseSocialLoginData: shouldEraseSocialLoginData)

        if let sessionTokens {
            try await persist(sessionTokens: sessionTokens)
        }

        await registrationStatusRepository.remove(registeredID: id)
    }

    private func unregisterUserWallet(
        id: UserWalletId,
        shouldEraseSocialLoginData: Bool
    ) async throws(UnregisterUserWalletError) -> SessionTokens? {
        do {
            return try await registrationClient.unregister(id: id, shouldEraseSocialLoginData: shouldEraseSocialLoginData)
        } catch UserWalletRegistrationClientError.wasNotRegistered {
            return nil
        } catch {
            throw UnregisterUserWalletError.clientFailure(error)
        }
    }

    private func persist(sessionTokens: SessionTokens) async throws(UnregisterUserWalletError) {
        do {
            try await sessionTokensRepository.persist(tokens: sessionTokens)
        } catch {
            throw UnregisterUserWalletError.repositoryFailure(error)
        }
    }
}
