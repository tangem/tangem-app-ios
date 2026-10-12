//
//  UnregisterUserWalletUseCaseTests.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import struct TangemFoundation.UserWalletId
@testable import TangemBackendAuthentication

@Suite(.tags(.backendAuthentication))
struct UnregisterUserWalletUseCaseTests {
    @Test
    func unregisterUserWalletUnregistersAndPersistsTokensOnSuccess() async throws {
        let expectedID = UserWalletId.uniqueFake()

        let registrationClient = SpyUserWalletRegistrationClient()
        let expectedSessionTokens = SessionTokens.uniqueFake()
        registrationClient.unregisterResult = Result.success(expectedSessionTokens)

        let sessionTokensRepository = SpySessionTokensRepository()
        sessionTokensRepository.persistResult = Result.success(())

        let registrationStatusRepository = SpyUserWalletRegistrationStatusRepository()

        let sut = makeSUT(
            registrationClient: registrationClient,
            registrationStatusRepository: registrationStatusRepository,
            sessionTokensRepository: sessionTokensRepository
        )

        try await sut(id: expectedID)

        #expect(registrationClient.receivedMessages == [.unregister(expectedID)])
        #expect(sessionTokensRepository.receivedMessages == [.persist(expectedSessionTokens)])
        #expect(registrationStatusRepository.receivedMessages == [.remove(expectedID)])
    }

    @Test
    func unregisterUserWalletPersistsStatusWithoutTokensWhenNotRegisteredOnServer() async throws {
        let expectedID = UserWalletId.uniqueFake()

        let registrationClient = SpyUserWalletRegistrationClient()
        registrationClient.unregisterResult = Result.failure(.wasNotRegistered)

        let sessionTokensRepository = SpySessionTokensRepository()
        let registrationStatusRepository = SpyUserWalletRegistrationStatusRepository()

        let sut = makeSUT(
            registrationClient: registrationClient,
            registrationStatusRepository: registrationStatusRepository,
            sessionTokensRepository: sessionTokensRepository
        )

        try await sut(id: expectedID)

        #expect(sessionTokensRepository.receivedMessages.isEmpty)
        #expect(registrationStatusRepository.receivedMessages == [.remove(expectedID)])
    }

    @Test
    func unregisterUserWalletThrowsClientFailureWhenUnregisterFails() async throws {
        let expectedID = UserWalletId.fake

        let registrationClient = SpyUserWalletRegistrationClient()
        let expectedUnderlyingError = AnyTestError()
        registrationClient.unregisterResult = Result.failure(.unregisterFailed(underlying: expectedUnderlyingError))

        let registrationStatusRepository = SpyUserWalletRegistrationStatusRepository()

        let sut = makeSUT(registrationClient: registrationClient, registrationStatusRepository: registrationStatusRepository)

        let error = try await #require(throws: UnregisterUserWalletError.self) {
            try await sut(id: expectedID)
        }

        guard case .clientFailure(.unregisterFailed(underlying: expectedUnderlyingError)) = error else {
            Issue.record("Expected .clientFailure(.unregisterFailed), got \(error)")
            return
        }

        #expect(registrationStatusRepository.receivedMessages.isEmpty)
    }

    @Test
    func unregisterUserWalletThrowsRepositoryFailureWhenPersistFails() async throws {
        let expectedID = UserWalletId.uniqueFake()

        let registrationClient = SpyUserWalletRegistrationClient()
        let expectedSessionTokens = SessionTokens.uniqueFake()
        registrationClient.unregisterResult = Result.success(expectedSessionTokens)

        let sessionTokensRepository = SpySessionTokensRepository()
        sessionTokensRepository.persistResult = Result.failure(.encodingFailed)

        let registrationStatusRepository = SpyUserWalletRegistrationStatusRepository()

        let sut = makeSUT(
            registrationClient: registrationClient,
            registrationStatusRepository: registrationStatusRepository,
            sessionTokensRepository: sessionTokensRepository
        )

        let error = try await #require(throws: UnregisterUserWalletError.self) {
            try await sut(id: expectedID)
        }

        guard case .repositoryFailure(.encodingFailed) = error else {
            Issue.record("Expected .repositoryFailure(.encodingFailed), got \(error)")
            return
        }

        #expect(registrationClient.receivedMessages == [.unregister(expectedID)])
        #expect(sessionTokensRepository.receivedMessages == [.persist(expectedSessionTokens)])
        #expect(registrationStatusRepository.receivedMessages.isEmpty)
    }
}

// MARK: - Factory methods

extension UnregisterUserWalletUseCaseTests {
    private func makeSUT(
        registrationClient: some UserWalletRegistrationClient = SpyUserWalletRegistrationClient(),
        registrationStatusRepository: some UserWalletRegistrationStatusRepository = SpyUserWalletRegistrationStatusRepository(),
        sessionTokensRepository: some SessionTokensRepository = SpySessionTokensRepository()
    ) -> UnregisterUserWalletUseCase {
        UnregisterUserWalletUseCase(
            registrationClient: registrationClient,
            registrationStatusRepository: registrationStatusRepository,
            sessionTokensRepository: sessionTokensRepository
        )
    }
}
