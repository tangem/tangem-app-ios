//
//  ObtainUserWalletRegistrationNonceUseCaseTests.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemFoundation
import TangemLogger
import TangemTestKit
@testable import TangemBackendAuthentication

@Suite(.tags(.backendAuthentication))
final class ObtainUserWalletRegistrationNonceUseCaseTests: LeakTrackingTestSuite {
    @Test
    func obtainNonceReturnsValidUserWalletRegistrationNonceOnSuccess() async throws {
        let appAttestService = SpyAppAttestService()
        let expectedAppAttestationToken = Data("some attestation token".utf8)
        appAttestService.generateAttestationTokenResult = Result.success(expectedAppAttestationToken)

        let registrationClient = SpyUserWalletRegistrationClient()
        let expectedCipheredNonce = "some ciphered nonce"
        registrationClient.requestCipheredNonceResult = Result.success(expectedCipheredNonce)

        let registrationStatusRepository = SpyUserWalletRegistrationStatusRepository()

        let devicePrivateKeyRepository = SpyDevicePrivateKeyRepository()
        let expectedDevicePrivateKey = StubDevicePrivateKey()
        devicePrivateKeyRepository.retrieveResult = Result.success(expectedDevicePrivateKey)
        let expectedDevicePublicKey = try expectedDevicePrivateKey.publicKey

        let expectedNonceBytesToSign = Data([0x01, 0x02, 0x03])
        let expectedDecryptedNonce = expectedNonceBytesToSign.base64URLEncodedString
        let expectedDecryptedNonceBytes = Data(expectedDecryptedNonce.utf8)

        let nonceDecryptor = SpyNonceDecryptor()
        nonceDecryptor.decryptResult = Result.success(expectedDecryptedNonceBytes)

        let sut = makeSUT(
            appAttestService: appAttestService,
            registrationClient: registrationClient,
            registrationStatusRepository: registrationStatusRepository,
            devicePrivateKeyRepository: devicePrivateKeyRepository,
            nonceDecryptor: nonceDecryptor
        )

        let expectedID = UserWalletId.uniqueFake()

        let nonce = try #require(await sut(id: expectedID))

        #expect(nonce.value == expectedDecryptedNonce)
        #expect(nonce.bytesToSign == expectedNonceBytesToSign)
        #expect(nonce.appAttestationToken == expectedAppAttestationToken)

        #expect(devicePrivateKeyRepository.receivedMessages == [.retrieve])
        #expect(nonceDecryptor.receivedMessages == [.decrypt(expectedCipheredNonce)])
        #expect(appAttestService.receivedMessages == [.generateAttestationToken(expectedDecryptedNonceBytes)])
        #expect(registrationClient.receivedMessages == [.requestCipheredNonce(expectedDevicePublicKey)])
        #expect(registrationStatusRepository.receivedMessages == [.retrieve(expectedID)])
    }

    @Test
    func obtainNonceSkipsRegistrationStatusCheckWhenIdIsNil() async throws {
        let registrationStatusRepository = SpyUserWalletRegistrationStatusRepository()

        let sut = makeSUT(
            registrationClient: .successStub,
            registrationStatusRepository: registrationStatusRepository,
            devicePrivateKeyRepository: .successStub,
            nonceDecryptor: .successStub
        )

        _ = try #require(await sut(id: nil))

        #expect(registrationStatusRepository.receivedMessages.isEmpty)
    }

    @Test
    func obtainNonceReturnsNilWhenAlreadyRegisteredLocally() async throws {
        let registrationClient = SpyUserWalletRegistrationClient()
        let registrationStatusRepository = SpyUserWalletRegistrationStatusRepository()
        registrationStatusRepository.retrieveResult = true

        let sut = makeSUT(
            registerDevice: Self.registerDeviceDummy(),
            registrationClient: registrationClient,
            registrationStatusRepository: registrationStatusRepository
        )

        let expectedID = UserWalletId.uniqueFake()

        let nonce = try await sut(id: expectedID)

        #expect(nonce == nil)
        #expect(registrationClient.receivedMessages.isEmpty)
        #expect(registrationStatusRepository.receivedMessages == [.retrieve(expectedID)])
    }

    @Test
    func obtainNonceSucceedsEvenWhenAttestationTokenGenerationFails() async throws {
        let appAttestService = SpyAppAttestService()
        appAttestService.generateAttestationTokenResult = Result.failure(AppAttestServiceError())

        let sut = makeSUT(
            appAttestService: appAttestService,
            registrationClient: .successStub,
            devicePrivateKeyRepository: .successStub,
            nonceDecryptor: .successStub
        )

        let nonce = try #require(await sut(id: UserWalletId.fake))

        #expect(nonce.appAttestationToken == nil)
    }

    @Test
    func obtainNonceThrowsDeviceRegistrationFailureWhenRegisterDeviceFails() async throws {
        let expectedUnderlyingError = AnyTestError()

        let sut = makeSUT(
            registerDevice: { () async throws(RegisterDeviceError) -> SessionTokens? in
                throw RegisterDeviceError.clientFailure(.requestNonceFailed(underlying: expectedUnderlyingError))
            }
        )

        let error = try await #require(throws: ObtainUserWalletRegistrationNonceError.self) {
            _ = try await sut(id: UserWalletId.fake)
        }

        guard
            case .deviceRegistrationFailure(.clientFailure(.requestNonceFailed(underlying: expectedUnderlyingError))) = error
        else {
            Issue.record("Expected .deviceRegistrationFailure(.clientFailure(.requestNonceFailed)), got \(error)")
            return
        }
    }

    @Test
    func obtainNonceThrowsDeviceKeyFailureWhenPublicKeyUnavailable() async throws {
        let devicePrivateKeyRepository = SpyDevicePrivateKeyRepository()
        let expectedUnderlyingError = AnyTestError()
        devicePrivateKeyRepository.retrieveResult = Result.failure(.keyGenerationFailed(underlying: expectedUnderlyingError))

        let sut = makeSUT(devicePrivateKeyRepository: devicePrivateKeyRepository)

        let error = try await #require(throws: ObtainUserWalletRegistrationNonceError.self) {
            _ = try await sut(id: UserWalletId.fake)
        }

        guard
            case .deviceKeyFailure(.privateKeyUnavailable(.keyGenerationFailed(underlying: let underlying))) = error,
            let underlyingAnyTestError = underlying as? AnyTestError,
            underlyingAnyTestError == expectedUnderlyingError
        else {
            Issue.record("Expected .deviceKeyFailure, got \(error)")
            return
        }
    }

    @Test
    func obtainNonceThrowsClientFailureWhenRequestCipheredNonceFails() async throws {
        let expectedUnderlyingError = AnyTestError()

        let registrationClient = SpyUserWalletRegistrationClient()
        registrationClient.requestCipheredNonceResult = Result.failure(.requestNonceFailed(underlying: expectedUnderlyingError))

        let sut = makeSUT(registrationClient: registrationClient, devicePrivateKeyRepository: .successStub)

        let error = try await #require(throws: ObtainUserWalletRegistrationNonceError.self) {
            _ = try await sut(id: UserWalletId.fake)
        }

        guard case .clientFailure(.requestNonceFailed(underlying: expectedUnderlyingError)) = error else {
            Issue.record("Expected .clientFailure(.requestNonceFailed), got \(error)")
            return
        }
    }

    @Test
    func obtainNonceThrowsNonceDecryptionFailureWhenDecryptFails() async throws {
        let nonceDecryptor = SpyNonceDecryptor()
        nonceDecryptor.decryptResult = Result.failure(.invalidCipheredNonceEncoding)

        let sut = makeSUT(
            registrationClient: .successStub,
            devicePrivateKeyRepository: .successStub,
            nonceDecryptor: nonceDecryptor
        )

        let error = try await #require(throws: ObtainUserWalletRegistrationNonceError.self) {
            _ = try await sut(id: UserWalletId.fake)
        }

        guard case .nonceDecryptionFailure(.invalidCipheredNonceEncoding) = error else {
            Issue.record("Expected .nonceDecryptionFailure(.invalidCipheredNonceEncoding), got \(error)")
            return
        }
    }

    @Test
    func obtainNonceThrowsInvalidDecryptedNonceEncodingWhenDecryptedNonceIsNotBase64URL() async throws {
        let nonceDecryptor = SpyNonceDecryptor()
        nonceDecryptor.decryptResult = Result.success(Data("not a base64 string ###".utf8))

        let sut = makeSUT(
            registrationClient: .successStub,
            devicePrivateKeyRepository: .successStub,
            nonceDecryptor: nonceDecryptor
        )

        let error = try await #require(throws: ObtainUserWalletRegistrationNonceError.self) {
            _ = try await sut(id: UserWalletId.fake)
        }

        guard case .invalidDecryptedNonceEncoding = error else {
            Issue.record("Expected .invalidDecryptedNonceEncoding, got \(error)")
            return
        }
    }
}

// MARK: - Factory methods

extension ObtainUserWalletRegistrationNonceUseCaseTests {
    func makeSUT(
        registerDevice: @escaping RegisterDevice = ObtainUserWalletRegistrationNonceUseCaseTests.registerDeviceFake(),
        appAttestService: some AppAttestService = SpyAppAttestService(),
        registrationClient: some UserWalletRegistrationClient = SpyUserWalletRegistrationClient(),
        registrationStatusRepository: some UserWalletRegistrationStatusRepository = SpyUserWalletRegistrationStatusRepository(),
        devicePrivateKeyRepository: some DevicePrivateKeyRepository = SpyDevicePrivateKeyRepository(),
        nonceDecryptor: some NonceDecryptor = SpyNonceDecryptor(),
        sourceLocation: SourceLocation = #_sourceLocation
    ) -> ObtainUserWalletRegistrationNonceUseCase {
        let deviceKeyManager = DeviceKeyManager(privateKeyRepository: devicePrivateKeyRepository)
        trackForMemoryLeaks(deviceKeyManager, sourceLocation: sourceLocation)

        return ObtainUserWalletRegistrationNonceUseCase(
            registerDevice: registerDevice,
            appAttestService: appAttestService,
            registrationClient: registrationClient,
            registrationStatusRepository: registrationStatusRepository,
            deviceKeyManager: deviceKeyManager,
            nonceDecryptor: nonceDecryptor,
            logger: Logger(category: OSLogCategory(name: "Tests"))
        )
    }

    private static func registerDeviceFake() -> RegisterDevice {
        { nil }
    }

    private static func registerDeviceDummy(sourceLocation: SourceLocation = #_sourceLocation) -> RegisterDevice {
        {
            Issue.record("Unexpected register device call.", sourceLocation: sourceLocation)
            return nil
        }
    }
}
