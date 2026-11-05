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
import TangemLogger
import TangemTestKit
@testable import TangemBackendAuthentication

@Suite(.tags(.backendAuthentication))
final class RegisterDeviceUseCaseTests: LeakTrackingTestSuite {
    @Test
    func registerDeviceRegistersDeviceAndPersistsTokensOnSuccess() async throws {
        let appAttestService = SpyAppAttestService()
        let expectedAppAttestation = AppAttestation(keyID: "some key id", object: Data("some attestation object".utf8))
        appAttestService.attestResult = Result.success(expectedAppAttestation)

        let registrationClient = SpyDeviceRegistrationClient()
        let expectedCipheredNonce = "some ciphered nonce"
        let expectedSessionTokens = SessionTokens.uniqueFake()
        registrationClient.requestCipheredNonceResult = Result.success(expectedCipheredNonce)
        registrationClient.registerResult = Result.success(expectedSessionTokens)

        let registrationStatusRepository = SpyDeviceRegistrationStatusRepository()

        let sessionTokensRepository = SpySessionTokensRepository()
        sessionTokensRepository.persistResult = Result.success(())

        let nonceDecryptor = SpyNonceDecryptor()
        let expectedDecryptedNonce = "some decrypted nonce"
        let expectedDecryptedNonceBytes = Data(expectedDecryptedNonce.utf8)
        nonceDecryptor.decryptResult = Result.success(expectedDecryptedNonceBytes)

        let expectedDevicePrivateKey = SpyDevicePrivateKey.successStub
        let devicePrivateKeyRepository = SpyDevicePrivateKeyRepository()
        devicePrivateKeyRepository.retrieveResult = Result.success(expectedDevicePrivateKey)

        let expectedRequest = try makeDeviceRegistrationRequest(
            devicePrivateKey: expectedDevicePrivateKey,
            decryptedNonce: expectedDecryptedNonce,
            appAttestation: expectedAppAttestation
        )

        let expectedSignedData = DeviceSignaturePayloadFactory.make(
            devicePublicKey: try expectedDevicePrivateKey.publicKeyResult.get(),
            decryptedNonce: expectedDecryptedNonce,
            attestationToken: expectedAppAttestation.object,
            metadata: DeviceMetadata.fake
        )

        let appAttestationStatusRepository = SpyAppAttestationStatusRepository()
        let analyticsReporter = SpyBackendAuthenticationNonceAnalyticsReporter()

        let sut = makeSUT(
            appAttestService: appAttestService,
            appAttestationStatusRepository: appAttestationStatusRepository,
            registrationClient: registrationClient,
            registrationStatusRepository: registrationStatusRepository,
            sessionTokensRepository: sessionTokensRepository,
            devicePrivateKeyRepository: devicePrivateKeyRepository,
            nonceDecryptor: nonceDecryptor,
            analyticsReporter: analyticsReporter
        )

        let sessionTokens = try await sut()

        #expect(sessionTokens == expectedSessionTokens)
        #expect(registrationClient.receivedMessages == [.requestCipheredNonce, .register(expectedRequest)])
        #expect(nonceDecryptor.receivedMessages == [.decrypt(expectedCipheredNonce)])
        #expect(appAttestService.receivedMessages == [.attest(expectedDecryptedNonceBytes)])
        #expect(expectedDevicePrivateKey.receivedMessages == [.publicKey, .signature(expectedSignedData)])
        #expect(sessionTokensRepository.receivedMessages == [.persist(expectedSessionTokens)])
        #expect(appAttestationStatusRepository.receivedMessages == [.persist(true)])
        #expect(registrationStatusRepository.receivedMessages == [.retrieve, .persist(isRegistered: true)])
        #expect(analyticsReporter.receivedMessages.isEmpty)
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
        let appAttestService = SpyAppAttestService()
        appAttestService.attestResult = Result.success(AppAttestation.fake)

        let registrationClient = SpyDeviceRegistrationClient()
        registrationClient.requestCipheredNonceResult = Result.success("any ciphered nonce")
        registrationClient.registerResult = Result.failure(.alreadyRegistered)

        let nonceDecryptor = SpyNonceDecryptor()
        let expectedDecryptedNonceBytes = Data("any decrypted nonce".utf8)
        nonceDecryptor.decryptResult = Result.success(expectedDecryptedNonceBytes)

        let registrationStatusRepository = SpyDeviceRegistrationStatusRepository()
        let sessionTokensRepository = SpySessionTokensRepository()
        let appAttestationStatusRepository = SpyAppAttestationStatusRepository()

        let sut = makeSUT(
            appAttestService: appAttestService,
            appAttestationStatusRepository: appAttestationStatusRepository,
            registrationClient: registrationClient,
            registrationStatusRepository: registrationStatusRepository,
            sessionTokensRepository: sessionTokensRepository,
            devicePrivateKeyRepository: .successStub,
            nonceDecryptor: nonceDecryptor
        )

        let sessionTokens = try await sut()

        #expect(sessionTokens == nil)
        #expect(appAttestService.receivedMessages == [.attest(expectedDecryptedNonceBytes)])
        #expect(appAttestationStatusRepository.receivedMessages == [.persist(false)])
        #expect(registrationStatusRepository.receivedMessages == [.retrieve, .persist(isRegistered: true)])
        #expect(sessionTokensRepository.receivedMessages.isEmpty)
    }

    @Test
    func registerDeviceSucceedsEvenWhenAttestationFails() async throws {
        let appAttestService = SpyAppAttestService()
        appAttestService.attestResult = Result.failure(.attestationFailed(underlying: AnyTestError()))

        let registrationClient = SpyDeviceRegistrationClient()
        registrationClient.requestCipheredNonceResult = Result.success("any ciphered nonce")
        let expectedSessionTokens = SessionTokens.uniqueFake()
        registrationClient.registerResult = Result.success(expectedSessionTokens)

        let nonceDecryptor = SpyNonceDecryptor()
        let expectedDecryptedNonce = "any decrypted nonce"
        let expectedDecryptedNonceBytes = Data(expectedDecryptedNonce.utf8)
        nonceDecryptor.decryptResult = Result.success(expectedDecryptedNonceBytes)

        let expectedDevicePrivateKey = SpyDevicePrivateKey.successStub
        let devicePrivateKeyRepository = SpyDevicePrivateKeyRepository()
        devicePrivateKeyRepository.retrieveResult = Result.success(expectedDevicePrivateKey)

        let expectedRequest = try makeDeviceRegistrationRequest(
            devicePrivateKey: expectedDevicePrivateKey,
            decryptedNonce: expectedDecryptedNonce,
            appAttestation: nil
        )

        let expectedSignedData = DeviceSignaturePayloadFactory.make(
            devicePublicKey: try expectedDevicePrivateKey.publicKeyResult.get(),
            decryptedNonce: expectedDecryptedNonce,
            attestationToken: nil,
            metadata: DeviceMetadata.fake
        )

        let appAttestationStatusRepository = SpyAppAttestationStatusRepository()

        let sut = makeSUT(
            appAttestService: appAttestService,
            appAttestationStatusRepository: appAttestationStatusRepository,
            registrationClient: registrationClient,
            sessionTokensRepository: .successStub,
            devicePrivateKeyRepository: devicePrivateKeyRepository,
            nonceDecryptor: nonceDecryptor
        )

        let sessionTokens = try await sut()

        #expect(sessionTokens == expectedSessionTokens)
        #expect(appAttestService.receivedMessages == [.attest(expectedDecryptedNonceBytes)])
        #expect(registrationClient.receivedMessages == [.requestCipheredNonce, .register(expectedRequest)])
        #expect(expectedDevicePrivateKey.receivedMessages == [.publicKey, .signature(expectedSignedData)])
        #expect(appAttestationStatusRepository.receivedMessages == [.persist(false)])
    }

    @Test
    func registerDeviceDoesNotMarkAppAsAttestedWhenBackendIssuesNoRefreshToken() async throws {
        let appAttestService = SpyAppAttestService()
        appAttestService.attestResult = Result.success(AppAttestation.fake)

        let expectedSessionTokens = SessionTokens(
            accessToken: SessionTokens.Token(jwt: "any access jwt", expiresAt: Date.fake),
            refreshToken: nil,
            userWalletIDs: []
        )

        let registrationClient = SpyDeviceRegistrationClient()
        registrationClient.requestCipheredNonceResult = Result.success("any ciphered nonce")
        registrationClient.registerResult = Result.success(expectedSessionTokens)

        let nonceDecryptor = SpyNonceDecryptor()
        let expectedDecryptedNonceBytes = Data("any decrypted nonce".utf8)
        nonceDecryptor.decryptResult = Result.success(expectedDecryptedNonceBytes)

        let registrationStatusRepository = SpyDeviceRegistrationStatusRepository()
        let appAttestationStatusRepository = SpyAppAttestationStatusRepository()

        let sut = makeSUT(
            appAttestService: appAttestService,
            appAttestationStatusRepository: appAttestationStatusRepository,
            registrationClient: registrationClient,
            registrationStatusRepository: registrationStatusRepository,
            sessionTokensRepository: .successStub,
            devicePrivateKeyRepository: .successStub,
            nonceDecryptor: nonceDecryptor
        )

        let sessionTokens = try await sut()

        #expect(sessionTokens == expectedSessionTokens)
        #expect(appAttestService.receivedMessages == [.attest(expectedDecryptedNonceBytes)])
        #expect(appAttestationStatusRepository.receivedMessages == [.persist(false)])
        #expect(registrationStatusRepository.receivedMessages == [.retrieve, .persist(isRegistered: true)])
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
    func registerDeviceReportsDeviceNonceTimeoutWhenRequestCipheredNonceTimesOut() async throws {
        let registrationClient = SpyDeviceRegistrationClient()
        registrationClient.requestCipheredNonceResult = Result.failure(.requestNonceTimeout)

        let analyticsReporter = SpyBackendAuthenticationNonceAnalyticsReporter()

        let sut = makeSUT(
            registrationClient: registrationClient,
            devicePrivateKeyRepository: .successStub,
            analyticsReporter: analyticsReporter
        )

        let error = try await #require(throws: RegisterDeviceError.self) {
            _ = try await sut()
        }

        guard case .clientFailure(.requestNonceTimeout) = error else {
            Issue.record("Expected .clientFailure(.requestNonceTimeout), got \(error)")
            return
        }

        #expect(analyticsReporter.receivedMessages == [.reportDeviceNonceTimeout])
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

        let devicePrivateKey = SpyDevicePrivateKey.successStub
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
        let expectedAppAttestation = AppAttestation(keyID: "some key id", object: Data("some attestation object".utf8))
        appAttestService.attestResult = Result.success(expectedAppAttestation)

        let registrationClient = SpyDeviceRegistrationClient()
        let expectedCipheredNonce = "some ciphered nonce"
        let expectedSessionTokens = SessionTokens.uniqueFake()
        registrationClient.requestCipheredNonceResult = Result.success(expectedCipheredNonce)
        registrationClient.registerResult = Result.success(expectedSessionTokens)

        let registrationStatusRepository = SpyDeviceRegistrationStatusRepository()

        let sessionTokensRepository = SpySessionTokensRepository()
        sessionTokensRepository.persistResult = Result.failure(SessionTokensRepositoryError.encodingFailed)

        let nonceDecryptor = SpyNonceDecryptor()
        let expectedDecryptedNonce = "some decrypted nonce"
        let expectedDecryptedNonceBytes = Data(expectedDecryptedNonce.utf8)
        nonceDecryptor.decryptResult = Result.success(expectedDecryptedNonceBytes)

        let expectedDevicePrivateKey = SpyDevicePrivateKey.successStub
        let devicePrivateKeyRepository = SpyDevicePrivateKeyRepository()
        devicePrivateKeyRepository.retrieveResult = Result.success(expectedDevicePrivateKey)

        let expectedRequest = try makeDeviceRegistrationRequest(
            devicePrivateKey: expectedDevicePrivateKey,
            decryptedNonce: expectedDecryptedNonce,
            appAttestation: expectedAppAttestation
        )

        let appAttestationStatusRepository = SpyAppAttestationStatusRepository()
        let analyticsReporter = SpyBackendAuthenticationNonceAnalyticsReporter()

        let sut = makeSUT(
            appAttestService: appAttestService,
            appAttestationStatusRepository: appAttestationStatusRepository,
            registrationClient: registrationClient,
            registrationStatusRepository: registrationStatusRepository,
            sessionTokensRepository: sessionTokensRepository,
            devicePrivateKeyRepository: devicePrivateKeyRepository,
            nonceDecryptor: nonceDecryptor,
            analyticsReporter: analyticsReporter
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
        #expect(appAttestService.receivedMessages == [.attest(expectedDecryptedNonceBytes)])
        #expect(appAttestationStatusRepository.receivedMessages.isEmpty)
        #expect(sessionTokensRepository.receivedMessages == [.persist(expectedSessionTokens)])
        #expect(registrationStatusRepository.receivedMessages == [.retrieve, .persist(isRegistered: false)])
        #expect(analyticsReporter.receivedMessages.isEmpty)
    }

    @Test
    func registerDeviceCoalescesConcurrentCalls() async throws {
        let expectedSessionTokens = SessionTokens.uniqueFake()

        let appAttestService = SpyAppAttestService()
        let expectedAppAttestation = AppAttestation.fake
        appAttestService.attestResult = Result.success(expectedAppAttestation)

        let registrationClient = SpyDeviceRegistrationClient()
        registrationClient.requestCipheredNonceResult = Result.success("any ciphered nonce")
        registrationClient.registerResult = Result.success(expectedSessionTokens)

        let registrationStatusRepository = SpyDeviceRegistrationStatusRepository()
        registrationStatusRepository.retrieveResult = false

        let sessionTokensRepository = SpySessionTokensRepository()
        sessionTokensRepository.persistResult = Result.success(())

        let nonceDecryptor = SpyNonceDecryptor()
        let expectedDecryptedNonce = "any decrypted nonce"
        let expectedDecryptedNonceBytes = Data(expectedDecryptedNonce.utf8)
        nonceDecryptor.decryptResult = Result.success(expectedDecryptedNonceBytes)

        let expectedDevicePrivateKey = SpyDevicePrivateKey.successStub
        let devicePrivateKeyRepository = SpyDevicePrivateKeyRepository()
        devicePrivateKeyRepository.retrieveResult = Result.success(expectedDevicePrivateKey)

        let expectedRequest = try makeDeviceRegistrationRequest(
            devicePrivateKey: expectedDevicePrivateKey,
            decryptedNonce: expectedDecryptedNonce,
            appAttestation: expectedAppAttestation
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
        #expect(appAttestService.receivedMessages == [.attest(expectedDecryptedNonceBytes)])
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
        let firstExpectedAppAttestation = AppAttestation(keyID: "first key id", object: Data("first attestation object".utf8))
        appAttestService.attestResult = Result.success(firstExpectedAppAttestation)

        let registrationClient = SpyDeviceRegistrationClient()
        registrationClient.requestCipheredNonceResult = Result.success("any ciphered nonce")
        registrationClient.registerResult = Result.failure(.registerFailed(underlying: AnyTestError()))

        let sessionTokensRepository = SpySessionTokensRepository()
        sessionTokensRepository.persistResult = Result.success(())

        let nonceDecryptor = SpyNonceDecryptor()
        let expectedDecryptedNonce = "any decrypted nonce"
        let expectedDecryptedNonceBytes = Data(expectedDecryptedNonce.utf8)
        nonceDecryptor.decryptResult = Result.success(expectedDecryptedNonceBytes)

        let expectedDevicePrivateKey = SpyDevicePrivateKey.successStub
        let devicePrivateKeyRepository = SpyDevicePrivateKeyRepository()
        devicePrivateKeyRepository.retrieveResult = Result.success(expectedDevicePrivateKey)

        let firstExpectedRequest = try makeDeviceRegistrationRequest(
            devicePrivateKey: expectedDevicePrivateKey,
            decryptedNonce: expectedDecryptedNonce,
            appAttestation: firstExpectedAppAttestation
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

        #expect(appAttestService.receivedMessages == [.attest(expectedDecryptedNonceBytes)])
        #expect(registrationClient.receivedMessages == [.requestCipheredNonce, .register(firstExpectedRequest)])

        let secondExpectedAppAttestation = AppAttestation(keyID: "second key id", object: Data("second attestation object".utf8))
        appAttestService.attestResult = Result.success(secondExpectedAppAttestation)

        let freshSessionTokensAfterRetry = SessionTokens.uniqueFake()
        registrationClient.registerResult = Result.success(freshSessionTokensAfterRetry)

        let secondExpectedRequest = try makeDeviceRegistrationRequest(
            devicePrivateKey: expectedDevicePrivateKey,
            decryptedNonce: expectedDecryptedNonce,
            appAttestation: secondExpectedAppAttestation
        )

        let actualSessionTokens = try await sut()

        #expect(actualSessionTokens == freshSessionTokensAfterRetry)
        #expect(appAttestService.receivedMessages == [
            .attest(expectedDecryptedNonceBytes),
            .attest(expectedDecryptedNonceBytes),
        ])
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
        appAttestationStatusRepository: some AppAttestationStatusRepository = SpyAppAttestationStatusRepository(),
        registrationClient: some DeviceRegistrationClient = SpyDeviceRegistrationClient(),
        registrationStatusRepository: some DeviceRegistrationStatusRepository = SpyDeviceRegistrationStatusRepository(),
        sessionTokensRepository: some SessionTokensRepository = SpySessionTokensRepository(),
        devicePrivateKeyRepository: some DevicePrivateKeyRepository = SpyDevicePrivateKeyRepository(),
        nonceDecryptor: some NonceDecryptor = SpyNonceDecryptor(),
        analyticsReporter: some BackendAuthenticationNonceAnalyticsReporter = SpyBackendAuthenticationNonceAnalyticsReporter(),
        sourceLocation: SourceLocation = #_sourceLocation
    ) -> RegisterDeviceUseCase {
        trackForMemoryLeaks(
            RegisterDeviceUseCase(
                appAttestService: appAttestService,
                appAttestationStatusRepository: appAttestationStatusRepository,
                registrationClient: registrationClient,
                registrationStatusRepository: registrationStatusRepository,
                sessionTokensRepository: sessionTokensRepository,
                deviceKeyManager: DeviceKeyManager(privateKeyRepository: devicePrivateKeyRepository),
                nonceDecryptor: nonceDecryptor,
                deviceMetadataProvider: DeviceMetadata.fake,
                analyticsReporter: analyticsReporter,
                logger: Logger(category: OSLogCategory(name: "Tests"))
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
        devicePrivateKey: SpyDevicePrivateKey,
        decryptedNonce: String,
        appAttestation: AppAttestation?
    ) throws -> DeviceRegistrationRequest {
        let ecdsaSignature = try devicePrivateKey.signResult.get()

        return DeviceRegistrationRequest(
            devicePublicKey: try devicePrivateKey.publicKeyResult.get(),
            decryptedNonce: decryptedNonce,
            metadata: DeviceMetadata.fake,
            signature: try DeviceSignature(
                derRepresentation: ecdsaSignature.derRepresentation,
                rawRepresentation: ecdsaSignature.rawRepresentation
            ),
            appAttestation: appAttestation
        )
    }
}
