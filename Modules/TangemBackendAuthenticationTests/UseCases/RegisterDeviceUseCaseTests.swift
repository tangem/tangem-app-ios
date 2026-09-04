//
//  RegisterDeviceUseCaseTests.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemTestKit
@testable import TangemBackendAuthentication

@Suite(.tags(.backendAuthentication))
final class RegisterDeviceUseCaseTests: LeakTrackingTestSuite {
    @Test
    func registerDeviceReturnsNilWhenAlreadyRegisteredLocally() async throws {
        let deviceRegistrationClient = SpyDeviceRegistrationClient()
        let sut = makeSUT(
            deviceRegistrationClient: deviceRegistrationClient,
            deviceRegistrationStatusRepository: StubDeviceRegistrationStatusRepository(retrieveResult: true)
        )

        let sessionTokens = try await sut()

        #expect(sessionTokens == nil)
        #expect(deviceRegistrationClient.receivedMessages.isEmpty)
    }

    @Test
    func registerDeviceRegistersDeviceAndPersistsTokensOnSuccess() async throws {
        let expectedSessionTokens = SessionTokens.stub
        let expectedAttestationToken = StubAppAttestService.stubbedAttestationToken

        let deviceRegistrationClient = SpyDeviceRegistrationClient(registerResult: .success(expectedSessionTokens))
        let sessionTokensRepository = SpySessionTokensRepository()
        let deviceRegistrationStatusRepository = SpyDeviceRegistrationStatusRepository()

        let sut = makeSUT(
            deviceRegistrationClient: deviceRegistrationClient,
            sessionTokensRepository: sessionTokensRepository,
            deviceRegistrationStatusRepository: deviceRegistrationStatusRepository
        )

        let sessionTokens = try await sut()

        #expect(sessionTokens == expectedSessionTokens)
        #expect(deviceRegistrationClient.receivedMessages == [.requestCipheredNonce, .register(expectedAttestationToken)])
        #expect(sessionTokensRepository.receivedMessages == [.persist(expectedSessionTokens)])
        #expect(deviceRegistrationStatusRepository.receivedMessages == [.retrieve, .persist(isRegistered: true)])
    }

    @Test
    func registerDeviceReturnsNilAndPersistsFlagWhenAlreadyRegisteredOnServer() async throws {
        let deviceRegistrationClient = StubDeviceRegistrationClient(registerResult: .failure(.alreadyRegistered))
        let sessionTokensRepository = SpySessionTokensRepository()
        let deviceRegistrationStatusRepository = SpyDeviceRegistrationStatusRepository()

        let sut = makeSUT(
            deviceRegistrationClient: deviceRegistrationClient,
            sessionTokensRepository: sessionTokensRepository,
            deviceRegistrationStatusRepository: deviceRegistrationStatusRepository
        )

        let sessionTokens = try await sut()

        #expect(sessionTokens == nil)
        #expect(sessionTokensRepository.receivedMessages.isEmpty)
        #expect(deviceRegistrationStatusRepository.receivedMessages == [.retrieve, .persist(isRegistered: true)])
    }

    @Test
    func registerDeviceSucceedsEvenWhenAttestationFails() async throws {
        let expectedSessionTokens = SessionTokens.stub
        let deviceRegistrationClient = SpyDeviceRegistrationClient(registerResult: .success(expectedSessionTokens))
        let appAttestService = StubAppAttestService(result: .failure(AppAttestServiceError()))

        let sut = makeSUT(
            appAttestService: appAttestService,
            deviceRegistrationClient: deviceRegistrationClient,
            deviceRegistrationStatusRepository: FakeDeviceRegistrationStatusRepository()
        )

        let sessionTokens = try await sut()

        #expect(sessionTokens == expectedSessionTokens)
        #expect(deviceRegistrationClient.receivedMessages == [.requestCipheredNonce, .register(nil)])
    }

    @Test
    func registerDeviceThrowsClientFailureWhenRequestCipheredNonceFails() async throws {
        let deviceRegistrationClient = StubDeviceRegistrationClient(
            requestCipheredNonceResult: .failure(.requestNonceFailed(underlying: AnyTestError()))
        )

        let sut = makeSUT(
            deviceRegistrationClient: deviceRegistrationClient,
            deviceRegistrationStatusRepository: FakeDeviceRegistrationStatusRepository()
        )

        let error = try await #require(throws: RegisterDeviceError.self) {
            _ = try await sut()
        }

        guard case .clientFailure(.requestNonceFailed) = error else {
            Issue.record("Expected .clientFailure(.requestNonceFailed), got \(error)")
            return
        }
    }

    @Test
    func registerDeviceThrowsClientFailureWhenRegisterFails() async throws {
        let deviceRegistrationClient = StubDeviceRegistrationClient(
            registerResult: .failure(.registerFailed(underlying: AnyTestError()))
        )

        let sut = makeSUT(
            deviceRegistrationClient: deviceRegistrationClient,
            deviceRegistrationStatusRepository: FakeDeviceRegistrationStatusRepository()
        )

        let error = try await #require(throws: RegisterDeviceError.self) {
            _ = try await sut()
        }

        guard case .clientFailure(.registerFailed) = error else {
            Issue.record("Expected .clientFailure(.registerFailed), got \(error)")
            return
        }
    }

    @Test
    func registerDeviceThrowsNonceDecryptionFailureWhenDecryptFails() async throws {
        let sut = makeSUT(
            deviceRegistrationClient: FakeDeviceRegistrationClient(),
            deviceRegistrationStatusRepository: FakeDeviceRegistrationStatusRepository(),
            nonceDecryptor: StubNonceDecryptor(result: .failure(.invalidCipheredNonceEncoding))
        )

        let error = try await #require(throws: RegisterDeviceError.self) {
            _ = try await sut()
        }

        guard case .nonceDecryptionFailure(.invalidCipheredNonceEncoding) = error else {
            Issue.record("Expected .nonceDecryptionFailure(.invalidCipheredNonceEncoding), got \(error)")
            return
        }
    }

    @Test
    func registerDeviceThrowsDeviceKeyFailureWhenPrivateKeyUnavailable() async throws {
        let devicePrivateKeyRepository = StubDevicePrivateKeyRepository(
            result: .failure(.keyGenerationFailed(underlying: AnyTestError()))
        )

        let sut = makeSUT(
            deviceRegistrationClient: FakeDeviceRegistrationClient(),
            deviceRegistrationStatusRepository: FakeDeviceRegistrationStatusRepository(),
            devicePrivateKeyRepository: devicePrivateKeyRepository
        )

        let error = try await #require(throws: RegisterDeviceError.self) {
            _ = try await sut()
        }

        guard case .deviceKeyFailure = error else {
            Issue.record("Expected .deviceKeyFailure, got \(error)")
            return
        }
    }

    @Test
    func registerDeviceThrowsDeviceKeyFailureWhenSigningFails() async throws {
        let devicePrivateKeyRepository = StubDevicePrivateKeyRepository(
            result: .success(
                StubDevicePrivateKey(publicKeyResult: .success(try DevicePublicKey.fake), signResult: .failure(AnyTestError()))
            )
        )

        let sut = makeSUT(
            deviceRegistrationClient: FakeDeviceRegistrationClient(),
            deviceRegistrationStatusRepository: FakeDeviceRegistrationStatusRepository(),
            devicePrivateKeyRepository: devicePrivateKeyRepository
        )

        let error = try await #require(throws: RegisterDeviceError.self) {
            _ = try await sut()
        }

        guard case .deviceKeyFailure = error else {
            Issue.record("Expected .deviceKeyFailure, got \(error)")
            return
        }
    }

    @Test
    func registerDeviceThrowsRepositoryFailureWhenPersistFails() async throws {
        let deviceRegistrationClient = StubDeviceRegistrationClient(registerResult: .success(.stub))
        let sessionTokensRepository = SpySessionTokensRepository(persistResult: .failure(.encodingFailed))
        let deviceRegistrationStatusRepository = SpyDeviceRegistrationStatusRepository()

        let sut = makeSUT(
            deviceRegistrationClient: deviceRegistrationClient,
            sessionTokensRepository: sessionTokensRepository,
            deviceRegistrationStatusRepository: deviceRegistrationStatusRepository
        )

        let error = try await #require(throws: RegisterDeviceError.self) {
            _ = try await sut()
        }

        guard case .repositoryFailure(.encodingFailed) = error else {
            Issue.record("Expected .repositoryFailure(.encodingFailed), got \(error)")
            return
        }

        #expect(sessionTokensRepository.receivedMessages == [.persist(.stub)])
        #expect(deviceRegistrationStatusRepository.receivedMessages == [.retrieve, .persist(isRegistered: false)])
    }

    @Test
    func registerDeviceCoalescesConcurrentCalls() async throws {
        let expectedSessionTokens = SessionTokens.stub
        let expectedAttestationToken = StubAppAttestService.stubbedAttestationToken
        let deviceRegistrationClient = SpyDeviceRegistrationClient(registerResult: .success(expectedSessionTokens))

        let sut = makeSUT(
            deviceRegistrationClient: deviceRegistrationClient,
            deviceRegistrationStatusRepository: FakeDeviceRegistrationStatusRepository()
        )

        async let firstSessionTokens = sut()
        async let secondSessionTokens = sut()
        async let thirdSessionTokens = sut()

        let (actualFirstSessionTokens, actualSecondSessionTokens, actualThirdSessionTokens) = try await (
            firstSessionTokens,
            secondSessionTokens,
            thirdSessionTokens
        )

        #expect(actualFirstSessionTokens == expectedSessionTokens)
        #expect(actualSecondSessionTokens == expectedSessionTokens)
        #expect(actualThirdSessionTokens == expectedSessionTokens)
        #expect(deviceRegistrationClient.receivedMessages == [.requestCipheredNonce, .register(expectedAttestationToken)])
    }

    @Test
    func registerDeviceStartsFreshRegistrationAfterPreviousCallCompletes() async throws {
        let firstSessionTokens = SessionTokens.stub
        let secondSessionTokens = SessionTokens(
            accessToken: SessionTokens.Token(jwt: "second-access-jwt", expiresAt: Date.fake),
            refreshToken: SessionTokens.Token(jwt: "second-refresh-jwt", expiresAt: Date.fake),
            userWalletIDs: []
        )
        let expectedAttestationToken = StubAppAttestService.stubbedAttestationToken

        let deviceRegistrationClient = SpyDeviceRegistrationClient(registerResult: .success(firstSessionTokens))
        let sut = makeSUT(
            deviceRegistrationClient: deviceRegistrationClient,
            deviceRegistrationStatusRepository: FakeDeviceRegistrationStatusRepository()
        )

        let actualFirstSessionTokens = try await sut()

        deviceRegistrationClient.registerResult = .success(secondSessionTokens)
        let actualSecondSessionTokens = try await sut()

        #expect(actualFirstSessionTokens == firstSessionTokens)
        #expect(actualSecondSessionTokens == secondSessionTokens)
        #expect(deviceRegistrationClient.receivedMessages == [
            .requestCipheredNonce, .register(expectedAttestationToken),
            .requestCipheredNonce, .register(expectedAttestationToken),
        ])
    }

    @Test
    func registerDeviceCoalescesConcurrentFailures() async throws {
        let expectedAttestationToken = StubAppAttestService.stubbedAttestationToken
        let deviceRegistrationClient = SpyDeviceRegistrationClient(
            registerResult: .failure(.registerFailed(underlying: AnyTestError()))
        )

        let sut = makeSUT(
            deviceRegistrationClient: deviceRegistrationClient,
            deviceRegistrationStatusRepository: FakeDeviceRegistrationStatusRepository()
        )

        async let firstResult = Self.attemptRegistration(with: sut)
        async let secondResult = Self.attemptRegistration(with: sut)
        async let thirdResult = Self.attemptRegistration(with: sut)

        let (actualFirstResult, actualSecondResult, actualThirdResult) = await (firstResult, secondResult, thirdResult)

        for actualResult in [actualFirstResult, actualSecondResult, actualThirdResult] {
            guard case .failure(.clientFailure(.registerFailed)) = actualResult else {
                Issue.record("Expected .clientFailure(.registerFailed), got \(actualResult)")
                continue
            }
        }

        #expect(deviceRegistrationClient.receivedMessages == [.requestCipheredNonce, .register(expectedAttestationToken)])

        let freshSessionTokensAfterRetry = SessionTokens.stub
        deviceRegistrationClient.registerResult = .success(freshSessionTokensAfterRetry)

        let actualSessionTokens = try await sut()

        #expect(actualSessionTokens == freshSessionTokensAfterRetry)
        #expect(deviceRegistrationClient.receivedMessages == [
            .requestCipheredNonce, .register(expectedAttestationToken),
            .requestCipheredNonce, .register(expectedAttestationToken),
        ])
    }
}

extension RegisterDeviceUseCaseTests {
    func makeSUT(
        appAttestService: some AppAttestService = StubAppAttestService(),
        deviceRegistrationClient: some DeviceRegistrationClient,
        sessionTokensRepository: some SessionTokensRepository = SpySessionTokensRepository(),
        deviceRegistrationStatusRepository: some DeviceRegistrationStatusRepository,
        devicePrivateKeyRepository: some DevicePrivateKeyRepository = FakeDevicePrivateKeyRepository(),
        nonceDecryptor: some NonceDecryptor = StubNonceDecryptor(),
        sourceLocation: SourceLocation = #_sourceLocation
    ) -> RegisterDeviceUseCase {
        trackForMemoryLeaks(
            RegisterDeviceUseCase(
                appAttestService: appAttestService,
                registrationClient: deviceRegistrationClient,
                registrationStatusRepository: deviceRegistrationStatusRepository,
                sessionTokensRepository: sessionTokensRepository,
                deviceKeyManager: DeviceKeyManager(privateKeyRepository: devicePrivateKeyRepository),
                nonceDecryptor: nonceDecryptor,
                deviceMetadataProvider: .fake
            ),
            sourceLocation: sourceLocation
        )
    }

    static func attemptRegistration(with sut: RegisterDeviceUseCase) async -> Result<SessionTokens?, RegisterDeviceError> {
        do throws(RegisterDeviceError) {
            return .success(try await sut())
        } catch {
            return .failure(error)
        }
    }
}

// MARK: - Fixtures

private extension SessionTokens {
    static let stub = SessionTokens(
        accessToken: Token(jwt: "access-jwt", expiresAt: Date.fake),
        refreshToken: Token(jwt: "refresh-jwt", expiresAt: Date.fake),
        userWalletIDs: []
    )
}
