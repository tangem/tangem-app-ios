//
//  SubmitUserWalletRegistrationUseCaseTests.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import TangemBackendAuthentication

@Suite(.tags(.backendAuthentication))
struct SubmitUserWalletRegistrationUseCaseTests {
    @Test
    func submitRegistrationRegistersAndPersistsTokensOnSuccess() async throws {
        let request = UserWalletRegistrationRequest.fake

        let registrationClient = SpyUserWalletRegistrationClient()
        let expectedSessionTokens = SessionTokens.uniqueFake()
        registrationClient.registerResult = Result.success(expectedSessionTokens)

        let sessionTokensRepository = SpySessionTokensRepository()
        sessionTokensRepository.persistResult = Result.success(())

        let registrationStatusRepository = SpyUserWalletRegistrationStatusRepository()

        let sut = makeSUT(
            registrationClient: registrationClient,
            registrationStatusRepository: registrationStatusRepository,
            sessionTokensRepository: sessionTokensRepository
        )

        try await sut(request: request)

        #expect(registrationClient.receivedMessages == [.register(request)])
        #expect(sessionTokensRepository.receivedMessages == [.persist(expectedSessionTokens)])
        #expect(registrationStatusRepository.receivedMessages == [.persist(request.id)])
    }

    @Test
    func submitRegistrationPersistsStatusWithoutTokensWhenAlreadyRegisteredOnServer() async throws {
        let request = UserWalletRegistrationRequest.fake

        let registrationClient = SpyUserWalletRegistrationClient()
        registrationClient.registerResult = Result.failure(.alreadyRegistered)

        let sessionTokensRepository = SpySessionTokensRepository()
        let registrationStatusRepository = SpyUserWalletRegistrationStatusRepository()

        let sut = makeSUT(
            registrationClient: registrationClient,
            registrationStatusRepository: registrationStatusRepository,
            sessionTokensRepository: sessionTokensRepository
        )

        try await sut(request: request)

        #expect(sessionTokensRepository.receivedMessages.isEmpty)
        #expect(registrationStatusRepository.receivedMessages == [.persist(request.id)])
    }

    @Test
    func submitRegistrationThrowsClientFailureWhenRegisterFails() async throws {
        let request = UserWalletRegistrationRequest.fake

        let registrationClient = SpyUserWalletRegistrationClient()
        let expectedUnderlyingError = AnyTestError()
        registrationClient.registerResult = Result.failure(.registerFailed(underlying: expectedUnderlyingError))

        let registrationStatusRepository = SpyUserWalletRegistrationStatusRepository()

        let sut = makeSUT(registrationClient: registrationClient, registrationStatusRepository: registrationStatusRepository)

        let error = try await #require(throws: SubmitUserWalletRegistrationError.self) {
            try await sut(request: request)
        }

        guard case .clientFailure(.registerFailed(underlying: expectedUnderlyingError)) = error else {
            Issue.record("Expected .clientFailure(.registerFailed), got \(error)")
            return
        }

        #expect(registrationStatusRepository.receivedMessages.isEmpty)
    }

    @Test
    func submitRegistrationThrowsRepositoryFailureWhenPersistFails() async throws {
        let request = UserWalletRegistrationRequest.fake

        let registrationClient = SpyUserWalletRegistrationClient()
        let expectedSessionTokens = SessionTokens.uniqueFake()
        registrationClient.registerResult = Result.success(expectedSessionTokens)

        let sessionTokensRepository = SpySessionTokensRepository()
        sessionTokensRepository.persistResult = Result.failure(.encodingFailed)

        let registrationStatusRepository = SpyUserWalletRegistrationStatusRepository()

        let sut = makeSUT(
            registrationClient: registrationClient,
            registrationStatusRepository: registrationStatusRepository,
            sessionTokensRepository: sessionTokensRepository
        )

        let error = try await #require(throws: SubmitUserWalletRegistrationError.self) {
            try await sut(request: request)
        }

        guard case .repositoryFailure(.encodingFailed) = error else {
            Issue.record("Expected .repositoryFailure(.encodingFailed), got \(error)")
            return
        }

        #expect(registrationClient.receivedMessages == [.register(request)])
        #expect(sessionTokensRepository.receivedMessages == [.persist(expectedSessionTokens)])
        #expect(registrationStatusRepository.receivedMessages.isEmpty)
    }
}

// MARK: - Factory methods

extension SubmitUserWalletRegistrationUseCaseTests {
    private func makeSUT(
        registrationClient: some UserWalletRegistrationClient = SpyUserWalletRegistrationClient(),
        registrationStatusRepository: some UserWalletRegistrationStatusRepository = SpyUserWalletRegistrationStatusRepository(),
        sessionTokensRepository: some SessionTokensRepository = SpySessionTokensRepository()
    ) -> SubmitUserWalletRegistrationUseCase {
        SubmitUserWalletRegistrationUseCase(
            registrationClient: registrationClient,
            registrationStatusRepository: registrationStatusRepository,
            sessionTokensRepository: sessionTokensRepository
        )
    }
}
