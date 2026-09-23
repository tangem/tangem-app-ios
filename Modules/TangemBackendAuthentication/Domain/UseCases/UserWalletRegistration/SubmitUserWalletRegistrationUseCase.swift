//
//  SubmitUserWalletRegistrationUseCase.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

typealias SubmitUserWalletRegistration = @Sendable (
    _ request: UserWalletRegistrationRequest
) async throws(SubmitUserWalletRegistrationError) -> Void

public struct SubmitUserWalletRegistrationUseCase: Sendable {
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

    public func callAsFunction(request: UserWalletRegistrationRequest) async throws(SubmitUserWalletRegistrationError) {
        let sessionTokens = try await register(request: request)

        if let sessionTokens {
            try await persist(sessionTokens: sessionTokens)
        }

        await registrationStatusRepository.persist(registeredID: request.id)
    }

    private func register(request: UserWalletRegistrationRequest) async throws(SubmitUserWalletRegistrationError) -> SessionTokens? {
        do {
            return try await registrationClient.register(request: request)
        } catch UserWalletRegistrationClientError.alreadyRegistered {
            return nil
        } catch {
            throw SubmitUserWalletRegistrationError.clientFailure(error)
        }
    }

    private func persist(sessionTokens: SessionTokens) async throws(SubmitUserWalletRegistrationError) {
        do {
            try await sessionTokensRepository.persist(tokens: sessionTokens)
        } catch {
            throw SubmitUserWalletRegistrationError.repositoryFailure(error)
        }
    }
}
