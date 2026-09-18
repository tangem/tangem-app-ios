//
//  RegisterDeviceUseCaseTests.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import enum CryptoKit.P256
import Foundation
import Testing
import TangemTestKit
@testable import TangemBackendAuthentication

@Suite(.tags(.backendAuthentication))
final class RegisterDeviceUseCaseTests: LeakTrackingTestSuite {
    @Test
    func registerDeviceRegistersDeviceAndPersistsTokensOnSuccess() async throws {
        let appAttestService = SpyAppAttestService()
        let expectedAppAttestationToken = Data("some attestation token".utf8)
        appAttestService.generateAttestationTokenResult = Result.success(expectedAppAttestationToken)

        let registrationClient = SpyDeviceRegistrationClient()
        let expectedCipheredNonce = "some ciphered nonce"
        let expectedSessionTokens = SessionTokens.fake
        registrationClient.requestCipheredNonceResult = Result.success(expectedCipheredNonce)
        registrationClient.registerResult = Result.success(expectedSessionTokens)

        let registrationStatusRepository = SpyDeviceRegistrationStatusRepository()

        let sessionTokensRepository = SpySessionTokensRepository()
        sessionTokensRepository.persistResult = Result.success(())

        let nonceDecryptor = SpyNonceDecryptor()
        let expectedDecryptedNonce = "some decrypted nonce"
        let expectedDecryptedNonceBytes = Data(expectedDecryptedNonce.utf8)
        nonceDecryptor.decryptResult = Result.success(expectedDecryptedNonceBytes)

        let expectedDevicePrivateKey = StubDevicePrivateKey()
        let devicePrivateKeyRepository = SpyDevicePrivateKeyRepository()
        devicePrivateKeyRepository.retrieveResult = Result.success(expectedDevicePrivateKey)

        let expectedRequest = try makeDeviceRegistrationRequest(
            devicePrivateKey: expectedDevicePrivateKey,
            decryptedNonce: expectedDecryptedNonce,
            appAttestationToken: expectedAppAttestationToken
        )

        let sut = makeSUT(
            appAttestService: appAttestService,
            registrationClient: registrationClient,
            registrationStatusRepository: registrationStatusRepository,
            sessionTokensRepository: sessionTokensRepository,
            devicePrivateKeyRepository: devicePrivateKeyRepository,
            nonceDecryptor: nonceDecryptor
        )

        let sessionTokens = try await sut()

        #expect(sessionTokens == expectedSessionTokens)
        #expect(registrationClient.receivedMessages == [.requestCipheredNonce, .register(expectedRequest)])
        #expect(nonceDecryptor.receivedMessages == [.decrypt(expectedCipheredNonce)])
        #expect(appAttestService.receivedMessages == [.generateAttestationToken(expectedDecryptedNonceBytes)])
        #expect(sessionTokensRepository.receivedMessages == [.persist(expectedSessionTokens)])
        #expect(registrationStatusRepository.receivedMessages == [.retrieve, .persist(isRegistered: true)])
    }

    @Test
    func registerDeviceReturnsNilWhenAlreadyRegisteredLocally() async throws {
        let registrationClient = SpyDeviceRegistrationClient()
        let registrationStatusRepository = SpyDeviceRegistrationStatusRepository()
        registrationStatusRepository.retrieveResult = true

        let sut = makeSUT(registrationClient: registrationClient, registrationStatusRepository: registrationStatusRepository)

        let sessionTokens = try await sut()

        #expect(sessionTokens == nil)
        #expect(registrationClient.receivedMessages.isEmpty)
        #expect(registrationStatusRepository.receivedMessages == [.retrieve])
    }

    @Test
    func registerDeviceReturnsNilAndPersistsFlagWhenAlreadyRegisteredOnServer() async throws {
        let registrationClient = SpyDeviceRegistrationClient()
        registrationClient.requestCipheredNonceResult = Result.success("any ciphered nonce")
        registrationClient.registerResult = Result.failure(.alreadyRegistered)

        let registrationStatusRepository = SpyDeviceRegistrationStatusRepository()
        let sessionTokensRepository = SpySessionTokensRepository()

        let sut = makeSUT(
            appAttestService: .successStub,
            registrationClient: registrationClient,
            registrationStatusRepository: registrationStatusRepository,
            sessionTokensRepository: sessionTokensRepository,
            devicePrivateKeyRepository: .successStub,
            nonceDecryptor: .successStub
        )

        let sessionTokens = try await sut()

        #expect(sessionTokens == nil)
        #expect(registrationStatusRepository.receivedMessages == [.retrieve, .persist(isRegistered: true)])
        #expect(sessionTokensRepository.receivedMessages.isEmpty)
    }

    @Test
    func registerDeviceSucceedsEvenWhenAttestationFails() async throws {
        let appAttestService = SpyAppAttestService()
        appAttestService.generateAttestationTokenResult = Result.failure(AppAttestServiceError())

        let registrationClient = SpyDeviceRegistrationClient()
        registrationClient.requestCipheredNonceResult = Result.success("any ciphered nonce")
        let expectedSessionTokens = SessionTokens.fake
        registrationClient.registerResult = Result.success(expectedSessionTokens)

        let nonceDecryptor = SpyNonceDecryptor()
        let expectedDecryptedNonce = "any decrypted nonce"
        nonceDecryptor.decryptResult = Result.success(Data(expectedDecryptedNonce.utf8))

        let expectedDevicePrivateKey = StubDevicePrivateKey()
        let devicePrivateKeyRepository = SpyDevicePrivateKeyRepository()
        devicePrivateKeyRepository.retrieveResult = Result.success(expectedDevicePrivateKey)

        let expectedRequest = try makeDeviceRegistrationRequest(
            devicePrivateKey: expectedDevicePrivateKey,
            decryptedNonce: expectedDecryptedNonce,
            appAttestationToken: nil
        )

        let sut = makeSUT(
            appAttestService: appAttestService,
            registrationClient: registrationClient,
            sessionTokensRepository: .successStub,
            devicePrivateKeyRepository: devicePrivateKeyRepository,
            nonceDecryptor: nonceDecryptor
        )

        let sessionTokens = try await sut()

        #expect(sessionTokens == expectedSessionTokens)
        #expect(registrationClient.receivedMessages == [.requestCipheredNonce, .register(expectedRequest)])
    }

    @Test
    func registerDeviceThrowsClientFailureWhenRequestCipheredNonceFails() async throws {
        let registrationClient = SpyDeviceRegistrationClient()
        let underlyingError = AnyTestError()
        registrationClient.requestCipheredNonceResult = Result.failure(.requestNonceFailed(underlying: underlyingError))

        let sut = makeSUT(registrationClient: registrationClient, devicePrivateKeyRepository: .successStub)

        let error = try await #require(throws: RegisterDeviceError.self) {
            _ = try await sut()
        }

        guard case .clientFailure(.requestNonceFailed(underlying: underlyingError)) = error else {
            Issue.record("Expected .clientFailure(.requestNonceFailed), got \(error)")
            return
        }
    }

    @Test
    func registerDeviceThrowsClientFailureWhenRegisterFails() async throws {
        let registrationClient = SpyDeviceRegistrationClient()
        registrationClient.requestCipheredNonceResult = Result.success("any ciphered nonce")
        let underlyingError = AnyTestError()
        registrationClient.registerResult = Result.failure(.registerFailed(underlying: underlyingError))

        let sut = makeSUT(
            registrationClient: registrationClient,
            devicePrivateKeyRepository: .successStub,
            nonceDecryptor: .successStub
        )

        let error = try await #require(throws: RegisterDeviceError.self) {
            _ = try await sut()
        }

        guard case .clientFailure(.registerFailed(underlying: underlyingError)) = error else {
            Issue.record("Expected .clientFailure(.registerFailed), got \(error)")
            return
        }
    }

    @Test
    func registerDeviceThrowsNonceDecryptionFailureWhenDecryptFails() async throws {
        let registrationClient = SpyDeviceRegistrationClient()
        registrationClient.requestCipheredNonceResult = Result.success("any ciphered nonce")

        let nonceDecryptor = SpyNonceDecryptor()
        nonceDecryptor.decryptResult = Result.failure(.invalidCipheredNonceEncoding)

        let sut = makeSUT(
            registrationClient: registrationClient,
            devicePrivateKeyRepository: .successStub,
            nonceDecryptor: nonceDecryptor
        )

        let error = try await #require(throws: RegisterDeviceError.self) {
            _ = try await sut()
        }

        guard case RegisterDeviceError.nonceDecryptionFailure(.invalidCipheredNonceEncoding) = error else {
            Issue.record("Expected .nonceDecryptionFailure(.invalidCipheredNonceEncoding), got \(error)")
            return
        }
    }

    @Test
    func registerDeviceThrowsDeviceKeyFailureWhenPrivateKeyUnavailable() async throws {
        let devicePrivateKeyRepository = SpyDevicePrivateKeyRepository()
        let expectedUnderlyingError = AnyTestError()
        devicePrivateKeyRepository.retrieveResult = Result.failure(.keyGenerationFailed(underlying: expectedUnderlyingError))

        let sut = makeSUT(devicePrivateKeyRepository: devicePrivateKeyRepository)

        let error = try await #require(throws: RegisterDeviceError.self) {
            _ = try await sut()
        }

        guard
            case RegisterDeviceError.deviceKeyFailure(
                .privateKeyUnavailable(.keyGenerationFailed(underlying: let underlying))
            ) = error,
            let underlyingAnyTestError = underlying as? AnyTestError,
            underlyingAnyTestError == expectedUnderlyingError
        else {
            Issue.record("Expected .deviceKeyFailure, got \(error)")
            return
        }
    }

    @Test
    func registerDeviceThrowsDeviceKeyFailureWhenSigningFails() async throws {
        let registrationClient = SpyDeviceRegistrationClient()
        registrationClient.requestCipheredNonceResult = Result.success("any ciphered nonce")

        var devicePrivateKey = StubDevicePrivateKey()
        let expectedUnderlyingError = AnyTestError()
        devicePrivateKey.signResult = Result.failure(expectedUnderlyingError)

        let devicePrivateKeyRepository = SpyDevicePrivateKeyRepository()
        devicePrivateKeyRepository.retrieveResult = Result.success(devicePrivateKey)

        let sut = makeSUT(
            registrationClient: registrationClient,
            devicePrivateKeyRepository: devicePrivateKeyRepository,
            nonceDecryptor: .successStub
        )

        let error = try await #require(throws: RegisterDeviceError.self) {
            _ = try await sut()
        }

        guard case RegisterDeviceError.deviceKeyFailure(.signingFailed(underlying: expectedUnderlyingError)) = error else {
            Issue.record("Expected .deviceKeyFailure, got \(error)")
            return
        }
    }

    @Test
    func registerDeviceThrowsRepositoryFailureWhenPersistFails() async throws {
        let appAttestService = SpyAppAttestService()
        let expectedAppAttestationToken = Data("some attestation token".utf8)
        appAttestService.generateAttestationTokenResult = Result.success(expectedAppAttestationToken)

        let registrationClient = SpyDeviceRegistrationClient()
        let expectedCipheredNonce = "some ciphered nonce"
        let expectedSessionTokens = SessionTokens.fake
        registrationClient.requestCipheredNonceResult = Result.success(expectedCipheredNonce)
        registrationClient.registerResult = Result.success(expectedSessionTokens)

        let registrationStatusRepository = SpyDeviceRegistrationStatusRepository()

        let sessionTokensRepository = SpySessionTokensRepository()
        sessionTokensRepository.persistResult = Result.failure(SessionTokensRepositoryError.encodingFailed)

        let nonceDecryptor = SpyNonceDecryptor()
        let expectedDecryptedNonce = "some decrypted nonce"
        let expectedDecryptedNonceBytes = Data(expectedDecryptedNonce.utf8)
        nonceDecryptor.decryptResult = Result.success(expectedDecryptedNonceBytes)

        let expectedDevicePrivateKey = StubDevicePrivateKey()
        let devicePrivateKeyRepository = SpyDevicePrivateKeyRepository()
        devicePrivateKeyRepository.retrieveResult = Result.success(expectedDevicePrivateKey)

        let expectedRequest = try makeDeviceRegistrationRequest(
            devicePrivateKey: expectedDevicePrivateKey,
            decryptedNonce: expectedDecryptedNonce,
            appAttestationToken: expectedAppAttestationToken
        )

        let sut = makeSUT(
            appAttestService: appAttestService,
            registrationClient: registrationClient,
            registrationStatusRepository: registrationStatusRepository,
            sessionTokensRepository: sessionTokensRepository,
            devicePrivateKeyRepository: devicePrivateKeyRepository,
            nonceDecryptor: nonceDecryptor
        )

        let error = try await #require(throws: RegisterDeviceError.self) {
            _ = try await sut()
        }

        guard case .repositoryFailure(.encodingFailed) = error else {
            Issue.record("Expected .repositoryFailure(.encodingFailed), got \(error)")
            return
        }

        #expect(registrationClient.receivedMessages == [.requestCipheredNonce, .register(expectedRequest)])
        #expect(nonceDecryptor.receivedMessages == [.decrypt(expectedCipheredNonce)])
        #expect(appAttestService.receivedMessages == [.generateAttestationToken(expectedDecryptedNonceBytes)])
        #expect(sessionTokensRepository.receivedMessages == [.persist(expectedSessionTokens)])
        #expect(registrationStatusRepository.receivedMessages == [.retrieve, .persist(isRegistered: false)])
    }

    @Test
    func registerDeviceCoalescesConcurrentCalls() async throws {
        let expectedSessionTokens = SessionTokens.fake

        let appAttestService = SpyAppAttestService()
        let expectedAppAttestationToken = Data("some attestation token".utf8)
        appAttestService.generateAttestationTokenResult = Result.success(expectedAppAttestationToken)

        let registrationClient = SpyDeviceRegistrationClient()
        registrationClient.requestCipheredNonceResult = Result.success("any ciphered nonce")
        registrationClient.registerResult = Result.success(expectedSessionTokens)

        let registrationStatusRepository = SpyDeviceRegistrationStatusRepository()
        registrationStatusRepository.retrieveResult = false

        let sessionTokensRepository = SpySessionTokensRepository()
        sessionTokensRepository.persistResult = Result.success(())

        let nonceDecryptor = SpyNonceDecryptor()
        let expectedDecryptedNonce = "any decrypted nonce"
        nonceDecryptor.decryptResult = Result.success(Data(expectedDecryptedNonce.utf8))

        let expectedDevicePrivateKey = StubDevicePrivateKey()
        let devicePrivateKeyRepository = SpyDevicePrivateKeyRepository()
        devicePrivateKeyRepository.retrieveResult = Result.success(expectedDevicePrivateKey)

        let expectedRequest = try makeDeviceRegistrationRequest(
            devicePrivateKey: expectedDevicePrivateKey,
            decryptedNonce: expectedDecryptedNonce,
            appAttestationToken: expectedAppAttestationToken
        )

        let sut = makeSUT(
            appAttestService: appAttestService,
            registrationClient: registrationClient,
            registrationStatusRepository: registrationStatusRepository,
            sessionTokensRepository: sessionTokensRepository,
            devicePrivateKeyRepository: devicePrivateKeyRepository,
            nonceDecryptor: nonceDecryptor
        )

        async let firstSessionTokens = sut()
        async let secondSessionTokens = sut()
        async let thirdSessionTokens = sut()

        let (actualFirstSessionTokens, actualSecondSessionTokens, actualThirdSessionTokens) = try await (
            firstSessionTokens,
            secondSessionTokens,
            thirdSessionTokens
        )

        registrationStatusRepository.retrieveResult = true
        let sessionTokensAfterSuccessfulDeviceRegistration = try await sut()

        #expect(actualFirstSessionTokens == expectedSessionTokens)
        #expect(actualSecondSessionTokens == expectedSessionTokens)
        #expect(actualThirdSessionTokens == expectedSessionTokens)
        #expect(sessionTokensAfterSuccessfulDeviceRegistration == nil)
        #expect(registrationClient.receivedMessages == [.requestCipheredNonce, .register(expectedRequest)])
        #expect(registrationStatusRepository.receivedMessages == [
            .retrieve,
            .retrieve,
            .retrieve,
            .persist(isRegistered: true),
            .retrieve,
        ])
        #expect(sessionTokensRepository.receivedMessages == [.persist(expectedSessionTokens)])
    }

    @Test
    func registerDeviceCoalescesConcurrentFailures() async throws {
        let appAttestService = SpyAppAttestService()
        let firstExpectedAppAttestationToken = Data("first app attestation token".utf8)
        appAttestService.generateAttestationTokenResult = Result.success(firstExpectedAppAttestationToken)

        let registrationClient = SpyDeviceRegistrationClient()
        registrationClient.requestCipheredNonceResult = Result.success("any ciphered nonce")
        registrationClient.registerResult = Result.failure(.registerFailed(underlying: AnyTestError()))

        let sessionTokensRepository = SpySessionTokensRepository()
        sessionTokensRepository.persistResult = Result.success(())

        let nonceDecryptor = SpyNonceDecryptor()
        let expectedDecryptedNonce = "any decrypted nonce"
        nonceDecryptor.decryptResult = Result.success(Data(expectedDecryptedNonce.utf8))

        let expectedDevicePrivateKey = StubDevicePrivateKey()
        let devicePrivateKeyRepository = SpyDevicePrivateKeyRepository()
        devicePrivateKeyRepository.retrieveResult = Result.success(expectedDevicePrivateKey)

        let firstExpectedRequest = try makeDeviceRegistrationRequest(
            devicePrivateKey: expectedDevicePrivateKey,
            decryptedNonce: expectedDecryptedNonce,
            appAttestationToken: firstExpectedAppAttestationToken
        )

        let sut = makeSUT(
            appAttestService: appAttestService,
            registrationClient: registrationClient,
            sessionTokensRepository: sessionTokensRepository,
            devicePrivateKeyRepository: devicePrivateKeyRepository,
            nonceDecryptor: nonceDecryptor
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

        #expect(registrationClient.receivedMessages == [.requestCipheredNonce, .register(firstExpectedRequest)])

        let secondExpectedAppAttestationToken = Data("second app attestation token".utf8)
        appAttestService.generateAttestationTokenResult = Result.success(secondExpectedAppAttestationToken)

        let freshSessionTokensAfterRetry = SessionTokens.fake
        registrationClient.registerResult = Result.success(freshSessionTokensAfterRetry)

        let secondExpectedRequest = try makeDeviceRegistrationRequest(
            devicePrivateKey: expectedDevicePrivateKey,
            decryptedNonce: expectedDecryptedNonce,
            appAttestationToken: secondExpectedAppAttestationToken
        )

        let actualSessionTokens = try await sut()

        #expect(actualSessionTokens == freshSessionTokensAfterRetry)
        #expect(registrationClient.receivedMessages == [
            .requestCipheredNonce,
            .register(firstExpectedRequest),
            .requestCipheredNonce,
            .register(secondExpectedRequest),
        ])
        #expect(sessionTokensRepository.receivedMessages == [.persist(freshSessionTokensAfterRetry)])
    }
}

// MARK: - Factory methods

extension RegisterDeviceUseCaseTests {
    func makeSUT(
        appAttestService: some AppAttestService = SpyAppAttestService(),
        registrationClient: some DeviceRegistrationClient = SpyDeviceRegistrationClient(),
        registrationStatusRepository: some DeviceRegistrationStatusRepository = SpyDeviceRegistrationStatusRepository(),
        sessionTokensRepository: some SessionTokensRepository = SpySessionTokensRepository(),
        devicePrivateKeyRepository: some DevicePrivateKeyRepository = SpyDevicePrivateKeyRepository(),
        nonceDecryptor: some NonceDecryptor = SpyNonceDecryptor(),
        sourceLocation: SourceLocation = #_sourceLocation
    ) -> RegisterDeviceUseCase {
        trackForMemoryLeaks(
            RegisterDeviceUseCase(
                appAttestService: appAttestService,
                registrationClient: registrationClient,
                registrationStatusRepository: registrationStatusRepository,
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
            return Result.success(try await sut())
        } catch {
            return Result.failure(error)
        }
    }

    func makeDeviceRegistrationRequest(
        devicePrivateKey: StubDevicePrivateKey,
        decryptedNonce: String,
        appAttestationToken: Data?
    ) throws -> DeviceRegistrationRequest {
        let ecdsaSignature = try devicePrivateKey.signature(for: Data())

        return DeviceRegistrationRequest(
            devicePublicKey: try devicePrivateKey.publicKey,
            decryptedNonce: decryptedNonce,
            metadata: DeviceMetadata.fake,
            signature: try DeviceSignature(
                derRepresentation: ecdsaSignature.derRepresentation,
                rawRepresentation: ecdsaSignature.rawRepresentation
            ),
            appAttestationToken: appAttestationToken
        )
    }
}
