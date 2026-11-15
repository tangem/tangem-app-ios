//
//  RenewSessionTokensUseCaseTests.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemLogger
import TangemTestKit
@testable import TangemBackendAuthentication

@Suite(.tags(.backendAuthentication))
final class RenewSessionTokensUseCaseTests: LeakTrackingTestSuite {
    @Test
    func renewSessionTokensRefreshesWhenValidRefreshTokenCached() async throws {
        let dateNow = Date.now
        let fiveMinutesBefore = dateNow.addingTimeInterval(-60 * 5)
        let twentyMinutesAfter = dateNow.addingTimeInterval(60 * 20)

        let cachedSessionTokens = SessionTokens(
            accessToken: SessionTokens.Token(jwt: "stale-access-jwt", expiresAt: fiveMinutesBefore),
            refreshToken: SessionTokens.Token(jwt: "valid-refresh-jwt", expiresAt: twentyMinutesAfter),
            userWalletIDs: []
        )

        let expectedSessionTokens = SessionTokens.uniqueFake()

        let authenticationClient = SpySessionAuthenticationClient()
        authenticationClient.refreshResult = Result.success(expectedSessionTokens)

        let tokensRepository = SpySessionTokensRepository()
        tokensRepository.retrieveResult = Result.success(cachedSessionTokens)
        tokensRepository.persistResult = Result.success(())

        let sut = makeSUT(
            sessionAuthenticationClient: authenticationClient,
            sessionTokensRepository: tokensRepository,
            devicePrivateKeyRepository: .successStub,
            dateProvider: dateNow
        )

        let actualSessionTokens = try await sut()

        #expect(actualSessionTokens == expectedSessionTokens)
        #expect(authenticationClient.receivedMessages == [.refresh])
        #expect(tokensRepository.receivedMessages == [.retrieve, .persist(expectedSessionTokens)])
    }

    @Test
    func renewSessionTokensFallsBackToAuthenticateWhenNoCachedTokens() async throws {
        let appAttestService = SpyAppAttestService()
        let expectedAppAttestation = AppAttestation(keyID: "some key id", object: Data("some attestation object".utf8))
        appAttestService.attestResult = Result.success(expectedAppAttestation)

        let authenticationClient = SpySessionAuthenticationClient()
        let expectedCipheredNonce = "some ciphered nonce"
        let expectedSessionTokens = SessionTokens.uniqueFake()
        authenticationClient.requestCipheredNonceResult = Result.success(expectedCipheredNonce)
        authenticationClient.authenticateResult = Result.success(expectedSessionTokens)

        let tokensRepository = SpySessionTokensRepository()
        tokensRepository.retrieveResult = Result.success(nil)
        tokensRepository.persistResult = Result.success(())

        let nonceDecryptor = SpyNonceDecryptor()
        let expectedDecryptedNonce = "some decrypted nonce"
        let expectedDecryptedNonceBytes = Data(expectedDecryptedNonce.utf8)
        nonceDecryptor.decryptResult = Result.success(expectedDecryptedNonceBytes)

        let expectedDevicePrivateKey = SpyDevicePrivateKey.successStub
        let devicePrivateKeyRepository = SpyDevicePrivateKeyRepository()
        devicePrivateKeyRepository.retrieveResult = Result.success(expectedDevicePrivateKey)

        let expectedRequest = try SessionAuthenticationRequest.fake(
            devicePrivateKey: expectedDevicePrivateKey,
            decryptedNonce: expectedDecryptedNonce,
            appAttestToken: SessionAuthenticationRequest.AppAttestToken(attestation: expectedAppAttestation)
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
            sessionAuthenticationClient: authenticationClient,
            sessionTokensRepository: tokensRepository,
            devicePrivateKeyRepository: devicePrivateKeyRepository,
            nonceDecryptor: nonceDecryptor,
            analyticsReporter: analyticsReporter
        )

        let actualSessionTokens = try await sut()

        #expect(actualSessionTokens == expectedSessionTokens)
        #expect(authenticationClient.receivedMessages == [
            .requestCipheredNonce,
            .authenticate(expectedRequest),
        ])
        #expect(nonceDecryptor.receivedMessages == [.decrypt(expectedCipheredNonce)])
        #expect(appAttestService.receivedMessages == [.attest(expectedDecryptedNonceBytes)])
        #expect(expectedDevicePrivateKey.receivedMessages == [.publicKey, .signature(expectedSignedData)])
        #expect(appAttestationStatusRepository.receivedMessages == [.retrieve, .persist(true)])
        #expect(tokensRepository.receivedMessages == [.retrieve, .persist(expectedSessionTokens)])
        #expect(analyticsReporter.receivedMessages.isEmpty)
    }

    @Test
    func renewSessionTokensFallsBackToAuthenticateWhenRefreshTokenExpired() async throws {
        let dateNow = Date.now
        let oneMinuteBefore = dateNow.addingTimeInterval(-60)

        let expiredCachedSessionTokens = SessionTokens(
            accessToken: SessionTokens.Token(jwt: "stale-access-jwt", expiresAt: oneMinuteBefore),
            refreshToken: SessionTokens.Token(jwt: "expired-refresh-jwt", expiresAt: oneMinuteBefore),
            userWalletIDs: []
        )

        let expectedSessionTokens = SessionTokens.uniqueFake()

        let authenticationClient = SpySessionAuthenticationClient()
        authenticationClient.requestCipheredNonceResult = Result.success("any ciphered nonce")
        authenticationClient.authenticateResult = Result.success(expectedSessionTokens)

        let tokensRepository = SpySessionTokensRepository()
        tokensRepository.retrieveResult = Result.success(expiredCachedSessionTokens)
        tokensRepository.persistResult = Result.success(())

        let nonceDecryptor = SpyNonceDecryptor()
        let expectedDecryptedNonce = "any decrypted nonce"
        nonceDecryptor.decryptResult = Result.success(Data(expectedDecryptedNonce.utf8))

        let expectedDevicePrivateKey = SpyDevicePrivateKey.successStub
        let devicePrivateKeyRepository = SpyDevicePrivateKeyRepository()
        devicePrivateKeyRepository.retrieveResult = Result.success(expectedDevicePrivateKey)

        let expectedRequest = try SessionAuthenticationRequest.fake(
            devicePrivateKey: expectedDevicePrivateKey,
            decryptedNonce: expectedDecryptedNonce,
            appAttestToken: nil
        )

        let sut = makeSUT(
            sessionAuthenticationClient: authenticationClient,
            sessionTokensRepository: tokensRepository,
            devicePrivateKeyRepository: devicePrivateKeyRepository,
            nonceDecryptor: nonceDecryptor,
            dateProvider: dateNow
        )

        let actualSessionTokens = try await sut()

        #expect(actualSessionTokens == expectedSessionTokens)
        #expect(authenticationClient.receivedMessages == [.requestCipheredNonce, .authenticate(expectedRequest)])
    }

    @Test
    func renewSessionTokensFallsBackToAuthenticateWhenCachedTokensHaveNoRefreshToken() async throws {
        let cachedSessionTokensWithoutRefreshToken = SessionTokens(
            accessToken: SessionTokens.Token(jwt: "stale-access-jwt", expiresAt: Date.now),
            refreshToken: nil,
            userWalletIDs: []
        )

        let expectedSessionTokens = SessionTokens.uniqueFake()

        let authenticationClient = SpySessionAuthenticationClient()
        authenticationClient.requestCipheredNonceResult = Result.success("any ciphered nonce")
        authenticationClient.authenticateResult = Result.success(expectedSessionTokens)

        let tokensRepository = SpySessionTokensRepository()
        tokensRepository.retrieveResult = Result.success(cachedSessionTokensWithoutRefreshToken)
        tokensRepository.persistResult = Result.success(())

        let nonceDecryptor = SpyNonceDecryptor()
        let expectedDecryptedNonce = "any decrypted nonce"
        nonceDecryptor.decryptResult = Result.success(Data(expectedDecryptedNonce.utf8))

        let expectedDevicePrivateKey = SpyDevicePrivateKey.successStub
        let devicePrivateKeyRepository = SpyDevicePrivateKeyRepository()
        devicePrivateKeyRepository.retrieveResult = Result.success(expectedDevicePrivateKey)

        let expectedRequest = try SessionAuthenticationRequest.fake(
            devicePrivateKey: expectedDevicePrivateKey,
            decryptedNonce: expectedDecryptedNonce,
            appAttestToken: nil
        )

        let sut = makeSUT(
            sessionAuthenticationClient: authenticationClient,
            sessionTokensRepository: tokensRepository,
            devicePrivateKeyRepository: devicePrivateKeyRepository,
            nonceDecryptor: nonceDecryptor
        )

        let actualSessionTokens = try await sut()

        #expect(actualSessionTokens == expectedSessionTokens)
        #expect(authenticationClient.receivedMessages == [.requestCipheredNonce, .authenticate(expectedRequest)])
    }

    @Test
    func renewSessionTokensFallsBackToAuthenticateWhenRefreshCallFails() async throws {
        let dateNow = Date.now
        let twentyMinutesAfter = dateNow.addingTimeInterval(60 * 20)

        let cachedSessionTokens = SessionTokens(
            accessToken: SessionTokens.Token(jwt: "stale-access-jwt", expiresAt: dateNow),
            refreshToken: SessionTokens.Token(jwt: "valid-refresh-jwt", expiresAt: twentyMinutesAfter),
            userWalletIDs: []
        )

        let expectedSessionTokens = SessionTokens.uniqueFake()

        let authenticationClient = SpySessionAuthenticationClient()
        authenticationClient.refreshResult = Result.failure(.refreshFailed(underlying: AnyTestError()))
        authenticationClient.requestCipheredNonceResult = Result.success("any ciphered nonce")
        authenticationClient.authenticateResult = Result.success(expectedSessionTokens)

        let tokensRepository = SpySessionTokensRepository()
        tokensRepository.retrieveResult = Result.success(cachedSessionTokens)
        tokensRepository.persistResult = Result.success(())

        let nonceDecryptor = SpyNonceDecryptor()
        let expectedDecryptedNonce = "any decrypted nonce"
        nonceDecryptor.decryptResult = Result.success(Data(expectedDecryptedNonce.utf8))

        let expectedDevicePrivateKey = SpyDevicePrivateKey.successStub
        let devicePrivateKeyRepository = SpyDevicePrivateKeyRepository()
        devicePrivateKeyRepository.retrieveResult = Result.success(expectedDevicePrivateKey)

        let expectedRequest = try SessionAuthenticationRequest.fake(
            devicePrivateKey: expectedDevicePrivateKey,
            decryptedNonce: expectedDecryptedNonce,
            appAttestToken: nil
        )

        let sut = makeSUT(
            sessionAuthenticationClient: authenticationClient,
            sessionTokensRepository: tokensRepository,
            devicePrivateKeyRepository: devicePrivateKeyRepository,
            nonceDecryptor: nonceDecryptor,
            dateProvider: dateNow
        )

        let actualSessionTokens = try await sut()

        #expect(actualSessionTokens == expectedSessionTokens)
        #expect(authenticationClient.receivedMessages == [.refresh, .requestCipheredNonce, .authenticate(expectedRequest)])
    }

    @Test
    func renewSessionTokensPropagatesRepositoryFailureWhenRetrieveFails() async throws {
        let authenticationClient = SpySessionAuthenticationClient()

        let tokensRepository = SpySessionTokensRepository()
        tokensRepository.retrieveResult = Result.failure(.decodingFailed)

        let sut = makeSUT(sessionAuthenticationClient: authenticationClient, sessionTokensRepository: tokensRepository)

        let actualError = try await #require(throws: RenewSessionTokensError.self) {
            _ = try await sut()
        }

        guard case .repositoryFailure(.decodingFailed) = actualError else {
            Issue.record("Expected .repositoryFailure(.decodingFailed), got \(actualError)")
            return
        }

        #expect(authenticationClient.receivedMessages.isEmpty)
        #expect(tokensRepository.receivedMessages == [.retrieve])
    }

    @Test
    func renewSessionTokensDeletesSessionTokensWhenAuthenticationRejected() async throws {
        let authenticationClient = SpySessionAuthenticationClient()
        authenticationClient.requestCipheredNonceResult = Result.success("any ciphered nonce")
        authenticationClient.authenticateResult = Result.failure(.authenticationRejected)

        let tokensRepository = SpySessionTokensRepository()
        tokensRepository.retrieveResult = Result.success(nil)
        tokensRepository.deleteResult = Result.success(())

        let sut = makeSUT(
            sessionAuthenticationClient: authenticationClient,
            sessionTokensRepository: tokensRepository,
            devicePrivateKeyRepository: .successStub,
            nonceDecryptor: .successStub
        )

        let actualError = try await #require(throws: RenewSessionTokensError.self) {
            _ = try await sut()
        }

        guard case .clientFailure(.authenticationRejected) = actualError else {
            Issue.record("Expected .clientFailure(.authenticationRejected), got \(actualError)")
            return
        }

        #expect(tokensRepository.receivedMessages == [.retrieve, .delete])
    }

    @Test
    func renewSessionTokensPropagatesAuthenticationRejectedEvenWhenDeleteFails() async throws {
        let authenticationClient = SpySessionAuthenticationClient()
        authenticationClient.requestCipheredNonceResult = Result.success("any ciphered nonce")
        authenticationClient.authenticateResult = Result.failure(.authenticationRejected)

        let tokensRepository = SpySessionTokensRepository()
        tokensRepository.retrieveResult = Result.success(nil)
        tokensRepository.deleteResult = Result.failure(.keychainFailure(.deleteFailed(status: -1)))

        let sut = makeSUT(
            sessionAuthenticationClient: authenticationClient,
            sessionTokensRepository: tokensRepository,
            devicePrivateKeyRepository: .successStub,
            nonceDecryptor: .successStub
        )

        let actualError = try await #require(throws: RenewSessionTokensError.self) {
            _ = try await sut()
        }

        guard case .clientFailure(.authenticationRejected) = actualError else {
            Issue.record("Expected .clientFailure(.authenticationRejected), got \(actualError)")
            return
        }

        #expect(tokensRepository.receivedMessages == [.retrieve, .delete])
    }

    @Test
    func renewSessionTokensDoesNotDeleteSessionTokensOnOtherAuthenticationFailures() async throws {
        let authenticationClient = SpySessionAuthenticationClient()
        let expectedUnderlyingError = AnyTestError()
        authenticationClient.requestCipheredNonceResult = Result.failure(.requestNonceFailed(underlying: expectedUnderlyingError))

        let tokensRepository = SpySessionTokensRepository()
        tokensRepository.retrieveResult = Result.success(nil)

        let sut = makeSUT(
            sessionAuthenticationClient: authenticationClient,
            sessionTokensRepository: tokensRepository,
            devicePrivateKeyRepository: .successStub
        )

        let actualError = try await #require(throws: RenewSessionTokensError.self) {
            _ = try await sut()
        }

        guard case .clientFailure(.requestNonceFailed(underlying: expectedUnderlyingError)) = actualError else {
            Issue.record("Expected .clientFailure(.requestNonceFailed), got \(actualError)")
            return
        }

        #expect(authenticationClient.receivedMessages == [.requestCipheredNonce])
        #expect(tokensRepository.receivedMessages == [.retrieve])
    }

    @Test
    func renewSessionTokensReportsAuthenticationNonceTimeoutWhenRequestCipheredNonceTimesOut() async throws {
        let authenticationClient = SpySessionAuthenticationClient()
        authenticationClient.requestCipheredNonceResult = Result.failure(.requestNonceTimeout)

        let tokensRepository = SpySessionTokensRepository()
        tokensRepository.retrieveResult = Result.success(nil)

        let analyticsReporter = SpyBackendAuthenticationNonceAnalyticsReporter()

        let sut = makeSUT(
            sessionAuthenticationClient: authenticationClient,
            sessionTokensRepository: tokensRepository,
            devicePrivateKeyRepository: .successStub,
            analyticsReporter: analyticsReporter
        )

        let actualError = try await #require(throws: RenewSessionTokensError.self) {
            _ = try await sut()
        }

        guard case .clientFailure(.requestNonceTimeout) = actualError else {
            Issue.record("Expected .clientFailure(.requestNonceTimeout), got \(actualError)")
            return
        }

        #expect(analyticsReporter.receivedMessages == [.reportAuthenticationNonceTimeout])
    }

    @Test
    func renewSessionTokensReusesTokensFromRegistrationOnDeviceRegistrationMissingError() async throws {
        let tokensFromRegistration = SessionTokens.uniqueFake()

        let authenticationClient = SpySessionAuthenticationClient()
        authenticationClient.requestCipheredNonceResult = Result.success("any ciphered nonce")
        authenticationClient.authenticateResult = Result.failure(.deviceRegistrationMissing)

        let tokensRepository = SpySessionTokensRepository()
        tokensRepository.retrieveResult = Result.success(nil)
        tokensRepository.persistResult = Result.success(())

        let deviceRegistrationStatusRepository = SpyDeviceRegistrationStatusRepository()
        let userWalletRegistrationStatusRepository = SpyUserWalletRegistrationStatusRepository()

        let nonceDecryptor = SpyNonceDecryptor()
        let expectedDecryptedNonce = "any decrypted nonce"
        nonceDecryptor.decryptResult = Result.success(Data(expectedDecryptedNonce.utf8))

        let expectedDevicePrivateKey = SpyDevicePrivateKey.successStub
        let devicePrivateKeyRepository = SpyDevicePrivateKeyRepository()
        devicePrivateKeyRepository.retrieveResult = Result.success(expectedDevicePrivateKey)

        let expectedRequest = try SessionAuthenticationRequest.fake(
            devicePrivateKey: expectedDevicePrivateKey,
            decryptedNonce: expectedDecryptedNonce,
            appAttestToken: nil
        )

        let appAttestationStatusRepository = SpyAppAttestationStatusRepository()

        let registerDevice = SpyRegisterDevice()
        registerDevice.registerDeviceResults = [Result.success(nil), Result.success(tokensFromRegistration)]

        let sut = makeSUT(
            registerDevice: registerDevice.callAsFunction,
            appAttestationStatusRepository: appAttestationStatusRepository,
            sessionAuthenticationClient: authenticationClient,
            sessionTokensRepository: tokensRepository,
            deviceRegistrationStatusRepository: deviceRegistrationStatusRepository,
            userWalletRegistrationStatusRepository: userWalletRegistrationStatusRepository,
            devicePrivateKeyRepository: devicePrivateKeyRepository,
            nonceDecryptor: nonceDecryptor
        )

        let actualSessionTokens = try await sut()

        #expect(actualSessionTokens == tokensFromRegistration)
        #expect(registerDevice.receivedMessages == [.registerDevice, .registerDevice])
        #expect(authenticationClient.receivedMessages == [.requestCipheredNonce, .authenticate(expectedRequest)])
        #expect(appAttestationStatusRepository.receivedMessages == [.retrieve, .persist(false)])
        #expect(deviceRegistrationStatusRepository.receivedMessages == [.persist(isRegistered: false)])
        #expect(tokensRepository.receivedMessages == [.retrieve, .persist(tokensFromRegistration)])
        #expect(userWalletRegistrationStatusRepository.receivedMessages == [.replaceAll(tokensFromRegistration.userWalletIDs)])
    }

    @Test
    func renewSessionTokensRetriesAuthenticateOnceWhenDeviceAlreadyRegistered() async throws {
        let expectedSessionTokens = SessionTokens.uniqueFake()

        let authenticationClient = SpySessionAuthenticationClient()
        authenticationClient.requestCipheredNonceResult = Result.success("any ciphered nonce")
        authenticationClient.authenticateResult = Result.failure(.deviceRegistrationMissing)

        let tokensRepository = SpySessionTokensRepository()
        tokensRepository.retrieveResult = Result.success(nil)
        tokensRepository.persistResult = Result.success(())

        let userWalletRegistrationStatusRepository = SpyUserWalletRegistrationStatusRepository()

        let nonceDecryptor = SpyNonceDecryptor()
        let expectedDecryptedNonce = "any decrypted nonce"
        nonceDecryptor.decryptResult = Result.success(Data(expectedDecryptedNonce.utf8))

        let expectedDevicePrivateKey = SpyDevicePrivateKey.successStub
        let devicePrivateKeyRepository = SpyDevicePrivateKeyRepository()
        devicePrivateKeyRepository.retrieveResult = Result.success(expectedDevicePrivateKey)

        let expectedRequest = try SessionAuthenticationRequest.fake(
            devicePrivateKey: expectedDevicePrivateKey,
            decryptedNonce: expectedDecryptedNonce,
            appAttestToken: nil
        )

        let appAttestationStatusRepository = SpyAppAttestationStatusRepository()

        let registerDeviceSpy = SpyRegisterDevice()
        registerDeviceSpy.registerDeviceResults = [Result.success(nil), Result.success(nil)]

        // [REDACTED_TODO_COMMENT]
        let registerDevice: RegisterDevice = {
            let freshSessionTokens = try await registerDeviceSpy.callAsFunction()

            if registerDeviceSpy.receivedMessages.count == 2 {
                authenticationClient.authenticateResult = Result.success(expectedSessionTokens)
            }

            return freshSessionTokens
        }

        let sut = makeSUT(
            registerDevice: registerDevice,
            appAttestationStatusRepository: appAttestationStatusRepository,
            sessionAuthenticationClient: authenticationClient,
            sessionTokensRepository: tokensRepository,
            userWalletRegistrationStatusRepository: userWalletRegistrationStatusRepository,
            devicePrivateKeyRepository: devicePrivateKeyRepository,
            nonceDecryptor: nonceDecryptor
        )

        let actualSessionTokens = try await sut()

        #expect(actualSessionTokens == expectedSessionTokens)
        #expect(registerDeviceSpy.receivedMessages == [.registerDevice, .registerDevice])
        #expect(authenticationClient.receivedMessages == [
            .requestCipheredNonce, .authenticate(expectedRequest),
            .requestCipheredNonce, .authenticate(expectedRequest),
        ])
        #expect(appAttestationStatusRepository.receivedMessages == [.retrieve, .persist(false), .retrieve])
        #expect(tokensRepository.receivedMessages == [.retrieve, .persist(expectedSessionTokens)])
        #expect(userWalletRegistrationStatusRepository.receivedMessages == [.replaceAll(expectedSessionTokens.userWalletIDs)])
    }

    @Test
    func renewSessionTokensPropagatesSecondAuthenticationFailureWithNoFurtherRecovery() async throws {
        let authenticationClient = SpySessionAuthenticationClient()
        authenticationClient.requestCipheredNonceResult = Result.success("any ciphered nonce")
        authenticationClient.authenticateResult = Result.failure(.deviceRegistrationMissing)

        let tokensRepository = SpySessionTokensRepository()
        tokensRepository.retrieveResult = Result.success(nil)

        let userWalletRegistrationStatusRepository = SpyUserWalletRegistrationStatusRepository()

        let nonceDecryptor = SpyNonceDecryptor()
        let expectedDecryptedNonce = "any decrypted nonce"
        nonceDecryptor.decryptResult = Result.success(Data(expectedDecryptedNonce.utf8))

        let expectedDevicePrivateKey = SpyDevicePrivateKey.successStub
        let devicePrivateKeyRepository = SpyDevicePrivateKeyRepository()
        devicePrivateKeyRepository.retrieveResult = Result.success(expectedDevicePrivateKey)

        let expectedRequest = try SessionAuthenticationRequest.fake(
            devicePrivateKey: expectedDevicePrivateKey,
            decryptedNonce: expectedDecryptedNonce,
            appAttestToken: nil
        )

        let sut = makeSUT(
            sessionAuthenticationClient: authenticationClient,
            sessionTokensRepository: tokensRepository,
            userWalletRegistrationStatusRepository: userWalletRegistrationStatusRepository,
            devicePrivateKeyRepository: devicePrivateKeyRepository,
            nonceDecryptor: nonceDecryptor
        )

        let actualError = try await #require(throws: RenewSessionTokensError.self) {
            _ = try await sut()
        }

        guard case .clientFailure(.deviceRegistrationMissing) = actualError else {
            Issue.record("Expected .clientFailure(.deviceRegistrationMissing), got \(actualError)")
            return
        }

        #expect(authenticationClient.receivedMessages == [
            .requestCipheredNonce, .authenticate(expectedRequest),
            .requestCipheredNonce, .authenticate(expectedRequest),
        ])
        #expect(tokensRepository.receivedMessages == [.retrieve])
        #expect(userWalletRegistrationStatusRepository.receivedMessages.isEmpty)
    }

    @Test
    func renewSessionTokensPropagatesRegistrationFailure() async throws {
        let authenticationClient = SpySessionAuthenticationClient()
        authenticationClient.requestCipheredNonceResult = Result.success("any ciphered nonce")
        authenticationClient.authenticateResult = Result.failure(.deviceRegistrationMissing)

        let tokensRepository = SpySessionTokensRepository()
        tokensRepository.retrieveResult = Result.success(nil)

        let userWalletRegistrationStatusRepository = SpyUserWalletRegistrationStatusRepository()

        let registerDevice = SpyRegisterDevice()
        registerDevice.registerDeviceResults = [Result.success(nil), Result.failure(.repositoryFailure(.encodingFailed))]

        let sut = makeSUT(
            registerDevice: registerDevice.callAsFunction,
            sessionAuthenticationClient: authenticationClient,
            sessionTokensRepository: tokensRepository,
            userWalletRegistrationStatusRepository: userWalletRegistrationStatusRepository,
            devicePrivateKeyRepository: .successStub,
            nonceDecryptor: .successStub
        )

        let actualError = try await #require(throws: RenewSessionTokensError.self) {
            _ = try await sut()
        }

        guard case .registrationFailure(.repositoryFailure(.encodingFailed)) = actualError else {
            Issue.record("Expected .registrationFailure(.repositoryFailure(.encodingFailed)), got \(actualError)")
            return
        }

        #expect(registerDevice.receivedMessages == [.registerDevice, .registerDevice])
        #expect(tokensRepository.receivedMessages == [.retrieve])
        #expect(userWalletRegistrationStatusRepository.receivedMessages.isEmpty)
    }

    @Test
    func renewSessionTokensReturnsTokensFromRegistrationWhenDeviceIsNotRegistered() async throws {
        let tokensFromRegistration = SessionTokens.uniqueFake()

        let registerDevice = SpyRegisterDevice()
        registerDevice.registerDeviceResults = [Result.success(tokensFromRegistration)]

        let appAttestService = SpyAppAttestService()
        let authenticationClient = SpySessionAuthenticationClient()

        let tokensRepository = SpySessionTokensRepository()
        tokensRepository.retrieveResult = Result.success(nil)
        tokensRepository.persistResult = Result.success(())

        let userWalletRegistrationStatusRepository = SpyUserWalletRegistrationStatusRepository()

        let sut = makeSUT(
            registerDevice: registerDevice.callAsFunction,
            appAttestService: appAttestService,
            sessionAuthenticationClient: authenticationClient,
            sessionTokensRepository: tokensRepository,
            userWalletRegistrationStatusRepository: userWalletRegistrationStatusRepository
        )

        let actualSessionTokens = try await sut()

        #expect(actualSessionTokens == tokensFromRegistration)
        #expect(registerDevice.receivedMessages == [.registerDevice])
        #expect(authenticationClient.receivedMessages.isEmpty)
        #expect(appAttestService.receivedMessages.isEmpty)
        #expect(tokensRepository.receivedMessages == [.retrieve, .persist(tokensFromRegistration)])
        #expect(userWalletRegistrationStatusRepository.receivedMessages.isEmpty)
    }

    @Test
    func renewSessionTokensPropagatesRegistrationFailureBeforeAuthentication() async throws {
        let registerDevice = SpyRegisterDevice()
        registerDevice.registerDeviceResults = [Result.failure(.repositoryFailure(.encodingFailed))]

        let authenticationClient = SpySessionAuthenticationClient()

        let tokensRepository = SpySessionTokensRepository()
        tokensRepository.retrieveResult = Result.success(nil)

        let sut = makeSUT(
            registerDevice: registerDevice.callAsFunction,
            sessionAuthenticationClient: authenticationClient,
            sessionTokensRepository: tokensRepository
        )

        let actualError = try await #require(throws: RenewSessionTokensError.self) {
            _ = try await sut()
        }

        guard case .registrationFailure(.repositoryFailure(.encodingFailed)) = actualError else {
            Issue.record("Expected .registrationFailure(.repositoryFailure(.encodingFailed)), got \(actualError)")
            return
        }

        #expect(registerDevice.receivedMessages == [.registerDevice])
        #expect(authenticationClient.receivedMessages.isEmpty)
        #expect(tokensRepository.receivedMessages == [.retrieve])
    }

    @Test
    func renewSessionTokensRetriesOnceWithAttestationWhenBackendRejectsAppAttest() async throws {
        let appAssertion = AppAssertion(keyID: "any key id", object: Data("any assertion object".utf8))
        let appAttestation = AppAttestation(keyID: "another key id", object: Data("any attestation object".utf8))

        let appAttestService = SpyAppAttestService()
        appAttestService.assertResult = Result.success(appAssertion)
        appAttestService.attestResult = Result.success(appAttestation)

        let appAttestationStatusRepository = FakeAppAttestationStatusRepository()
        appAttestationStatusRepository.persist(isAppAttested: true)

        let authenticationClient = SpySessionAuthenticationClient()
        authenticationClient.requestCipheredNonceResult = Result.success("any ciphered nonce")
        authenticationClient.authenticateResult = Result.failure(.appAttestRejected)

        let tokensRepository = SpySessionTokensRepository()
        tokensRepository.retrieveResult = Result.success(nil)

        let nonceDecryptor = SpyNonceDecryptor()
        let expectedDecryptedNonce = "any decrypted nonce"
        let expectedDecryptedNonceBytes = Data(expectedDecryptedNonce.utf8)
        nonceDecryptor.decryptResult = Result.success(expectedDecryptedNonceBytes)

        let expectedDevicePrivateKey = SpyDevicePrivateKey.successStub
        let devicePrivateKeyRepository = SpyDevicePrivateKeyRepository()
        devicePrivateKeyRepository.retrieveResult = Result.success(expectedDevicePrivateKey)

        let expectedAssertionRequest = try SessionAuthenticationRequest.fake(
            devicePrivateKey: expectedDevicePrivateKey,
            decryptedNonce: expectedDecryptedNonce,
            appAttestToken: SessionAuthenticationRequest.AppAttestToken(assertion: appAssertion)
        )

        let expectedAttestationRequest = try SessionAuthenticationRequest.fake(
            devicePrivateKey: expectedDevicePrivateKey,
            decryptedNonce: expectedDecryptedNonce,
            appAttestToken: SessionAuthenticationRequest.AppAttestToken(attestation: appAttestation)
        )

        let sut = makeSUT(
            appAttestService: appAttestService,
            appAttestationStatusRepository: appAttestationStatusRepository,
            sessionAuthenticationClient: authenticationClient,
            sessionTokensRepository: tokensRepository,
            devicePrivateKeyRepository: devicePrivateKeyRepository,
            nonceDecryptor: nonceDecryptor
        )

        let actualError = try await #require(throws: RenewSessionTokensError.self) {
            _ = try await sut()
        }

        guard case .clientFailure(.appAttestRejected) = actualError else {
            Issue.record("Expected .clientFailure(.appAttestRejected), got \(actualError)")
            return
        }

        #expect(appAttestService.receivedMessages == [.assert(expectedDecryptedNonceBytes), .attest(expectedDecryptedNonceBytes)])
        #expect(authenticationClient.receivedMessages == [
            .requestCipheredNonce, .authenticate(expectedAssertionRequest),
            .requestCipheredNonce, .authenticate(expectedAttestationRequest),
        ])
        #expect(appAttestationStatusRepository.retrieve() == false)
        #expect(tokensRepository.receivedMessages == [.retrieve])
    }

    @Test(
        arguments: [
            AppAttestServiceError.deviceCheckUnsupported,
            AppAttestServiceError.attestationServerUnavailable,
            AppAttestServiceError.keyGenerationFailed(underlying: AnyTestError()),
        ]
    )
    func renewSessionTokensSucceedsEvenWhenAttestationFails(attestationError: AppAttestServiceError) async throws {
        let authenticationClient = SpySessionAuthenticationClient()
        let expectedSessionTokens = SessionTokens.uniqueFake()
        authenticationClient.requestCipheredNonceResult = Result.success("any ciphered nonce")
        authenticationClient.authenticateResult = Result.success(expectedSessionTokens)

        let nonceDecryptor = SpyNonceDecryptor()
        let expectedDecryptedNonce = "any decrypted nonce"
        let expectedDecryptedNonceBytes = Data(expectedDecryptedNonce.utf8)
        nonceDecryptor.decryptResult = Result.success(expectedDecryptedNonceBytes)

        let expectedDevicePrivateKey = SpyDevicePrivateKey.successStub
        let devicePrivateKeyRepository = SpyDevicePrivateKeyRepository()
        devicePrivateKeyRepository.retrieveResult = Result.success(expectedDevicePrivateKey)

        let expectedRequest = try SessionAuthenticationRequest.fake(
            devicePrivateKey: expectedDevicePrivateKey,
            decryptedNonce: expectedDecryptedNonce,
            appAttestToken: nil
        )

        let expectedSignedData = DeviceSignaturePayloadFactory.make(
            devicePublicKey: try expectedDevicePrivateKey.publicKeyResult.get(),
            decryptedNonce: expectedDecryptedNonce,
            attestationToken: nil,
            metadata: DeviceMetadata.fake
        )

        let appAttestService = SpyAppAttestService()
        appAttestService.attestResult = Result.failure(attestationError)

        let appAttestationStatusRepository = SpyAppAttestationStatusRepository()

        let sut = makeSUT(
            appAttestService: appAttestService,
            appAttestationStatusRepository: appAttestationStatusRepository,
            sessionAuthenticationClient: authenticationClient,
            sessionTokensRepository: .successStub,
            devicePrivateKeyRepository: devicePrivateKeyRepository,
            nonceDecryptor: nonceDecryptor
        )

        let actualSessionTokens = try await sut()

        #expect(actualSessionTokens == expectedSessionTokens)
        #expect(authenticationClient.receivedMessages == [.requestCipheredNonce, .authenticate(expectedRequest)])
        #expect(expectedDevicePrivateKey.receivedMessages == [.publicKey, .signature(expectedSignedData)])
        #expect(appAttestService.receivedMessages == [.attest(expectedDecryptedNonceBytes)])
        #expect(appAttestationStatusRepository.receivedMessages == [.retrieve])
    }

    @Test
    func renewSessionTokensPassesAttestationTokenWhenAvailable() async throws {
        let appAttestService = SpyAppAttestService()
        let expectedAppAttestation = AppAttestation(keyID: "any key id", object: Data([0xAA, 0xBB]))
        appAttestService.attestResult = Result.success(expectedAppAttestation)

        let authenticationClient = SpySessionAuthenticationClient()
        authenticationClient.requestCipheredNonceResult = Result.success("any ciphered nonce")
        authenticationClient.authenticateResult = Result.success(SessionTokens.fake)

        let nonceDecryptor = SpyNonceDecryptor()
        let expectedDecryptedNonce = "any decrypted nonce"
        let expectedDecryptedNonceBytes = Data(expectedDecryptedNonce.utf8)
        nonceDecryptor.decryptResult = Result.success(expectedDecryptedNonceBytes)

        let expectedDevicePrivateKey = SpyDevicePrivateKey.successStub
        let devicePrivateKeyRepository = SpyDevicePrivateKeyRepository()
        devicePrivateKeyRepository.retrieveResult = Result.success(expectedDevicePrivateKey)

        let expectedRequest = try SessionAuthenticationRequest.fake(
            devicePrivateKey: expectedDevicePrivateKey,
            decryptedNonce: expectedDecryptedNonce,
            appAttestToken: SessionAuthenticationRequest.AppAttestToken(attestation: expectedAppAttestation)
        )

        let expectedSignedData = DeviceSignaturePayloadFactory.make(
            devicePublicKey: try expectedDevicePrivateKey.publicKeyResult.get(),
            decryptedNonce: expectedDecryptedNonce,
            attestationToken: expectedAppAttestation.object,
            metadata: DeviceMetadata.fake
        )

        let sut = makeSUT(
            appAttestService: appAttestService,
            sessionAuthenticationClient: authenticationClient,
            sessionTokensRepository: .successStub,
            devicePrivateKeyRepository: devicePrivateKeyRepository,
            nonceDecryptor: nonceDecryptor
        )

        _ = try await sut()

        #expect(appAttestService.receivedMessages == [.attest(expectedDecryptedNonceBytes)])
        #expect(authenticationClient.receivedMessages == [.requestCipheredNonce, .authenticate(expectedRequest)])
        #expect(expectedDevicePrivateKey.receivedMessages == [.publicKey, .signature(expectedSignedData)])
    }

    @Test
    func renewSessionTokensPassesAssertionTokenWhenAppIsAttested() async throws {
        let appAttestService = SpyAppAttestService()
        let expectedAppAssertion = AppAssertion(keyID: "some key id", object: Data("some assertion object".utf8))
        appAttestService.assertResult = Result.success(expectedAppAssertion)

        let appAttestationStatusRepository = SpyAppAttestationStatusRepository()
        appAttestationStatusRepository.retrieveResult = true

        let authenticationClient = SpySessionAuthenticationClient()
        authenticationClient.requestCipheredNonceResult = Result.success("any ciphered nonce")
        authenticationClient.authenticateResult = Result.success(SessionTokens.fake)

        let nonceDecryptor = SpyNonceDecryptor()
        let expectedDecryptedNonce = "any decrypted nonce"
        let expectedDecryptedNonceBytes = Data(expectedDecryptedNonce.utf8)
        nonceDecryptor.decryptResult = Result.success(expectedDecryptedNonceBytes)

        let expectedDevicePrivateKey = SpyDevicePrivateKey.successStub
        let devicePrivateKeyRepository = SpyDevicePrivateKeyRepository()
        devicePrivateKeyRepository.retrieveResult = Result.success(expectedDevicePrivateKey)

        let expectedRequest = try SessionAuthenticationRequest.fake(
            devicePrivateKey: expectedDevicePrivateKey,
            decryptedNonce: expectedDecryptedNonce,
            appAttestToken: SessionAuthenticationRequest.AppAttestToken(assertion: expectedAppAssertion)
        )

        let expectedSignedData = DeviceSignaturePayloadFactory.make(
            devicePublicKey: try expectedDevicePrivateKey.publicKeyResult.get(),
            decryptedNonce: expectedDecryptedNonce,
            attestationToken: expectedAppAssertion.object,
            metadata: DeviceMetadata.fake
        )

        let sut = makeSUT(
            appAttestService: appAttestService,
            appAttestationStatusRepository: appAttestationStatusRepository,
            sessionAuthenticationClient: authenticationClient,
            sessionTokensRepository: .successStub,
            devicePrivateKeyRepository: devicePrivateKeyRepository,
            nonceDecryptor: nonceDecryptor
        )

        _ = try await sut()

        #expect(appAttestService.receivedMessages == [.assert(expectedDecryptedNonceBytes)])
        #expect(authenticationClient.receivedMessages == [.requestCipheredNonce, .authenticate(expectedRequest)])
        #expect(expectedDevicePrivateKey.receivedMessages == [.publicKey, .signature(expectedSignedData)])
        #expect(appAttestationStatusRepository.receivedMessages == [.retrieve])
    }

    @Test
    func renewSessionTokensDoesNotMarkAppAsAttestedWhenBackendIssuesNoRefreshToken() async throws {
        let appAttestService = SpyAppAttestService()
        appAttestService.attestResult = Result.success(AppAttestation.fake)

        let appAttestationStatusRepository = SpyAppAttestationStatusRepository()

        let expectedSessionTokens = SessionTokens(
            accessToken: SessionTokens.Token(jwt: "any access jwt", expiresAt: Date.fake),
            refreshToken: nil,
            userWalletIDs: []
        )

        let authenticationClient = SpySessionAuthenticationClient()
        authenticationClient.requestCipheredNonceResult = Result.success("any ciphered nonce")
        authenticationClient.authenticateResult = Result.success(expectedSessionTokens)

        let nonceDecryptor = SpyNonceDecryptor()
        let expectedDecryptedNonceBytes = Data("any decrypted nonce".utf8)
        nonceDecryptor.decryptResult = Result.success(expectedDecryptedNonceBytes)

        let sut = makeSUT(
            appAttestService: appAttestService,
            appAttestationStatusRepository: appAttestationStatusRepository,
            sessionAuthenticationClient: authenticationClient,
            sessionTokensRepository: .successStub,
            devicePrivateKeyRepository: .successStub,
            nonceDecryptor: nonceDecryptor
        )

        let sessionTokens = try await sut()

        #expect(sessionTokens == expectedSessionTokens)
        #expect(appAttestService.receivedMessages == [.attest(expectedDecryptedNonceBytes)])
        #expect(appAttestationStatusRepository.receivedMessages == [.retrieve])
    }

    @Test
    func renewSessionTokensClearsAppAttestationStatusWhenBackendDoesNotAcceptAssertion() async throws {
        let appAttestService = SpyAppAttestService()
        appAttestService.assertResult = Result.success(AppAssertion(keyID: "any key id", object: Data("any assertion object".utf8)))

        let appAttestationStatusRepository = SpyAppAttestationStatusRepository()
        appAttestationStatusRepository.retrieveResult = true

        let expectedSessionTokens = SessionTokens(
            accessToken: SessionTokens.Token(jwt: "any access jwt", expiresAt: Date.fake),
            refreshToken: nil,
            userWalletIDs: []
        )

        let authenticationClient = SpySessionAuthenticationClient()
        authenticationClient.requestCipheredNonceResult = Result.success("any ciphered nonce")
        authenticationClient.authenticateResult = Result.success(expectedSessionTokens)

        let nonceDecryptor = SpyNonceDecryptor()
        let expectedDecryptedNonceBytes = Data("any decrypted nonce".utf8)
        nonceDecryptor.decryptResult = Result.success(expectedDecryptedNonceBytes)

        let sut = makeSUT(
            appAttestService: appAttestService,
            appAttestationStatusRepository: appAttestationStatusRepository,
            sessionAuthenticationClient: authenticationClient,
            sessionTokensRepository: .successStub,
            devicePrivateKeyRepository: .successStub,
            nonceDecryptor: nonceDecryptor
        )

        let sessionTokens = try await sut()

        #expect(sessionTokens == expectedSessionTokens)
        #expect(appAttestService.receivedMessages == [.assert(expectedDecryptedNonceBytes)])
        #expect(appAttestationStatusRepository.receivedMessages == [.retrieve, .persist(false)])
    }

    @Test(arguments: [
        AppAttestServiceError.assertionKeyCorrupted,
        AppAttestServiceError.assertionKeyNotFound,
    ])
    func renewSessionTokensResetsAppAttestationStatusWhenAssertionKeyIsUnavailable(
        keyUnavailableError: AppAttestServiceError
    ) async throws {
        let appAttestService = SpyAppAttestService()
        appAttestService.assertResult = Result.failure(keyUnavailableError)

        let appAttestationStatusRepository = SpyAppAttestationStatusRepository()
        appAttestationStatusRepository.retrieveResult = true

        let authenticationClient = SpySessionAuthenticationClient()
        authenticationClient.requestCipheredNonceResult = Result.success("any ciphered nonce")
        authenticationClient.authenticateResult = Result.success(SessionTokens.fake)

        let nonceDecryptor = SpyNonceDecryptor()
        let expectedDecryptedNonce = "any decrypted nonce"
        let expectedDecryptedNonceBytes = Data(expectedDecryptedNonce.utf8)
        nonceDecryptor.decryptResult = Result.success(expectedDecryptedNonceBytes)

        let expectedDevicePrivateKey = SpyDevicePrivateKey.successStub
        let devicePrivateKeyRepository = SpyDevicePrivateKeyRepository()
        devicePrivateKeyRepository.retrieveResult = Result.success(expectedDevicePrivateKey)

        let expectedRequest = try SessionAuthenticationRequest.fake(
            devicePrivateKey: expectedDevicePrivateKey,
            decryptedNonce: expectedDecryptedNonce,
            appAttestToken: nil
        )

        let sut = makeSUT(
            appAttestService: appAttestService,
            appAttestationStatusRepository: appAttestationStatusRepository,
            sessionAuthenticationClient: authenticationClient,
            sessionTokensRepository: .successStub,
            devicePrivateKeyRepository: devicePrivateKeyRepository,
            nonceDecryptor: nonceDecryptor
        )

        _ = try await sut()

        #expect(appAttestService.receivedMessages == [.assert(expectedDecryptedNonceBytes)])
        #expect(authenticationClient.receivedMessages == [.requestCipheredNonce, .authenticate(expectedRequest)])
        #expect(appAttestationStatusRepository.receivedMessages == [.retrieve, .persist(false)])
    }

    @Test(arguments: [
        AppAttestServiceError.assertionFailed(underlying: AnyTestError()),
        AppAttestServiceError.keychainFailure(.retrieveFailed(status: errSecInteractionNotAllowed)),
        AppAttestServiceError.deviceCheckUnsupported,
    ])
    func renewSessionTokensKeepsAppAttestationStatusWhenAssertionFailsForOtherReasons(
        assertionError: AppAttestServiceError
    ) async throws {
        let appAttestService = SpyAppAttestService()
        appAttestService.assertResult = Result.failure(assertionError)

        let appAttestationStatusRepository = SpyAppAttestationStatusRepository()
        appAttestationStatusRepository.retrieveResult = true

        let authenticationClient = SpySessionAuthenticationClient()
        authenticationClient.requestCipheredNonceResult = Result.success("any ciphered nonce")
        authenticationClient.authenticateResult = Result.success(SessionTokens.fake)

        let nonceDecryptor = SpyNonceDecryptor()
        let expectedDecryptedNonce = "any decrypted nonce"
        let expectedDecryptedNonceBytes = Data(expectedDecryptedNonce.utf8)
        nonceDecryptor.decryptResult = Result.success(expectedDecryptedNonceBytes)

        let expectedDevicePrivateKey = SpyDevicePrivateKey.successStub
        let devicePrivateKeyRepository = SpyDevicePrivateKeyRepository()
        devicePrivateKeyRepository.retrieveResult = Result.success(expectedDevicePrivateKey)

        let expectedRequest = try SessionAuthenticationRequest.fake(
            devicePrivateKey: expectedDevicePrivateKey,
            decryptedNonce: expectedDecryptedNonce,
            appAttestToken: nil
        )

        let sut = makeSUT(
            appAttestService: appAttestService,
            appAttestationStatusRepository: appAttestationStatusRepository,
            sessionAuthenticationClient: authenticationClient,
            sessionTokensRepository: .successStub,
            devicePrivateKeyRepository: devicePrivateKeyRepository,
            nonceDecryptor: nonceDecryptor
        )

        _ = try await sut()

        #expect(appAttestService.receivedMessages == [.assert(expectedDecryptedNonceBytes)])
        #expect(authenticationClient.receivedMessages == [.requestCipheredNonce, .authenticate(expectedRequest)])
        #expect(appAttestationStatusRepository.receivedMessages == [.retrieve])
    }

    @Test
    func renewSessionTokensThrowsDeviceKeyFailureWhenPrivateKeyUnavailable() async throws {
        let devicePrivateKeyRepository = SpyDevicePrivateKeyRepository()
        let expectedUnderlyingError = AnyTestError()
        devicePrivateKeyRepository.retrieveResult = Result.failure(.keyGenerationFailed(underlying: expectedUnderlyingError))

        let sut = makeSUT(
            sessionTokensRepository: .successStub,
            devicePrivateKeyRepository: devicePrivateKeyRepository
        )

        let actualError = try await #require(throws: RenewSessionTokensError.self) {
            _ = try await sut()
        }

        guard
            case RenewSessionTokensError.deviceKeyFailure(
                DeviceKeyManagerError.privateKeyUnavailable(
                    DevicePrivateKeyRepositoryError.keyGenerationFailed(underlying: let underlying)
                )
            ) = actualError,
            let underlyingAnyTestError = underlying as? AnyTestError,
            underlyingAnyTestError == expectedUnderlyingError
        else {
            Issue.record("Expected .deviceKeyFailure, got \(actualError)")
            return
        }
    }

    @Test
    func renewSessionTokensThrowsNonceDecryptionFailureWhenDecryptFails() async throws {
        let nonceDecryptor = SpyNonceDecryptor()
        nonceDecryptor.decryptResult = Result.failure(.invalidCipheredNonceEncoding)

        let sut = makeSUT(
            sessionAuthenticationClient: .successStub,
            sessionTokensRepository: .successStub,
            devicePrivateKeyRepository: .successStub,
            nonceDecryptor: nonceDecryptor
        )

        let actualError = try await #require(throws: RenewSessionTokensError.self) {
            _ = try await sut()
        }

        guard case .nonceDecryptionFailure(.invalidCipheredNonceEncoding) = actualError else {
            Issue.record("Expected .nonceDecryptionFailure(.invalidCipheredNonceEncoding), got \(actualError)")
            return
        }
    }

    @Test
    func renewSessionTokensThrowsRepositoryFailureWhenPersistFails() async throws {
        let appAttestService = SpyAppAttestService()
        let expectedAppAttestation = AppAttestation(keyID: "some key id", object: Data("some attestation object".utf8))
        appAttestService.attestResult = Result.success(expectedAppAttestation)

        let authenticationClient = SpySessionAuthenticationClient()
        let expectedCipheredNonce = "some ciphered nonce"
        let expectedSessionTokens = SessionTokens.uniqueFake()
        authenticationClient.requestCipheredNonceResult = Result.success(expectedCipheredNonce)
        authenticationClient.authenticateResult = Result.success(expectedSessionTokens)

        let tokensRepository = SpySessionTokensRepository()
        tokensRepository.retrieveResult = Result.success(nil)
        tokensRepository.persistResult = Result.failure(.encodingFailed)

        let nonceDecryptor = SpyNonceDecryptor()
        let expectedDecryptedNonce = "some decrypted nonce"
        let expectedDecryptedNonceBytes = Data(expectedDecryptedNonce.utf8)
        nonceDecryptor.decryptResult = Result.success(expectedDecryptedNonceBytes)

        let expectedDevicePrivateKey = SpyDevicePrivateKey.successStub
        let devicePrivateKeyRepository = SpyDevicePrivateKeyRepository()
        devicePrivateKeyRepository.retrieveResult = Result.success(expectedDevicePrivateKey)

        let expectedRequest = try SessionAuthenticationRequest.fake(
            devicePrivateKey: expectedDevicePrivateKey,
            decryptedNonce: expectedDecryptedNonce,
            appAttestToken: SessionAuthenticationRequest.AppAttestToken(attestation: expectedAppAttestation)
        )

        let analyticsReporter = SpyBackendAuthenticationNonceAnalyticsReporter()

        let sut = makeSUT(
            appAttestService: appAttestService,
            sessionAuthenticationClient: authenticationClient,
            sessionTokensRepository: tokensRepository,
            devicePrivateKeyRepository: devicePrivateKeyRepository,
            nonceDecryptor: nonceDecryptor,
            analyticsReporter: analyticsReporter
        )

        let actualError = try await #require(throws: RenewSessionTokensError.self) {
            _ = try await sut()
        }

        guard case .repositoryFailure(.encodingFailed) = actualError else {
            Issue.record("Expected .repositoryFailure(.encodingFailed), got \(actualError)")
            return
        }

        #expect(authenticationClient.receivedMessages == [
            .requestCipheredNonce,
            .authenticate(expectedRequest),
        ])
        #expect(nonceDecryptor.receivedMessages == [.decrypt(expectedCipheredNonce)])
        #expect(appAttestService.receivedMessages == [.attest(expectedDecryptedNonceBytes)])
        #expect(tokensRepository.receivedMessages == [.retrieve, .persist(expectedSessionTokens)])
        #expect(analyticsReporter.receivedMessages.isEmpty)
    }

    @Test
    func renewSessionTokensCoalescesConcurrentCalls() async throws {
        let expectedSessionTokens = SessionTokens.uniqueFake()

        let authenticationClient = SpySessionAuthenticationClient()
        authenticationClient.requestCipheredNonceResult = Result.success("any ciphered nonce")
        authenticationClient.authenticateResult = Result.success(expectedSessionTokens)

        let nonceDecryptor = SpyNonceDecryptor()
        let expectedDecryptedNonce = "any decrypted nonce"
        nonceDecryptor.decryptResult = Result.success(Data(expectedDecryptedNonce.utf8))

        let expectedDevicePrivateKey = SpyDevicePrivateKey.successStub
        let devicePrivateKeyRepository = SpyDevicePrivateKeyRepository()
        devicePrivateKeyRepository.retrieveResult = Result.success(expectedDevicePrivateKey)

        let expectedRequest = try SessionAuthenticationRequest.fake(
            devicePrivateKey: expectedDevicePrivateKey,
            decryptedNonce: expectedDecryptedNonce,
            appAttestToken: nil
        )

        let sut = makeSUT(
            sessionAuthenticationClient: authenticationClient,
            sessionTokensRepository: .successStub,
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

        #expect(actualFirstSessionTokens == expectedSessionTokens)
        #expect(actualSecondSessionTokens == expectedSessionTokens)
        #expect(actualThirdSessionTokens == expectedSessionTokens)
        #expect(authenticationClient.receivedMessages == [.requestCipheredNonce, .authenticate(expectedRequest)])
    }

    @Test
    func renewSessionTokensStartsFreshRenewalAfterPreviousCallCompletes() async throws {
        let dateNow = Date.now

        let firstFreshSessionTokens = SessionTokens(
            accessToken: SessionTokens.Token(jwt: "first-access-jwt", expiresAt: dateNow.addingTimeInterval(60 * 10)),
            refreshToken: SessionTokens.Token(jwt: "first-refresh-jwt", expiresAt: dateNow.addingTimeInterval(60 * 60 * 24)),
            userWalletIDs: []
        )

        let secondFreshSessionTokens = SessionTokens(
            accessToken: SessionTokens.Token(jwt: "second-access-jwt", expiresAt: dateNow.addingTimeInterval(60 * 20)),
            refreshToken: SessionTokens.Token(jwt: "second-refresh-jwt", expiresAt: dateNow.addingTimeInterval(60 * 60 * 48)),
            userWalletIDs: []
        )

        let authenticationClient = SpySessionAuthenticationClient()
        authenticationClient.requestCipheredNonceResult = Result.success("any ciphered nonce")
        authenticationClient.authenticateResult = Result.success(firstFreshSessionTokens)

        let nonceDecryptor = SpyNonceDecryptor()
        let expectedDecryptedNonce = "any decrypted nonce"
        nonceDecryptor.decryptResult = Result.success(Data(expectedDecryptedNonce.utf8))

        let expectedDevicePrivateKey = SpyDevicePrivateKey.successStub
        let devicePrivateKeyRepository = SpyDevicePrivateKeyRepository()
        devicePrivateKeyRepository.retrieveResult = Result.success(expectedDevicePrivateKey)

        let expectedRequest = try SessionAuthenticationRequest.fake(
            devicePrivateKey: expectedDevicePrivateKey,
            decryptedNonce: expectedDecryptedNonce,
            appAttestToken: nil
        )

        let sut = makeSUT(
            sessionAuthenticationClient: authenticationClient,
            sessionTokensRepository: .successStub,
            devicePrivateKeyRepository: devicePrivateKeyRepository,
            nonceDecryptor: nonceDecryptor,
            dateProvider: dateNow
        )

        let actualFirstSessionTokens = try await sut()

        authenticationClient.authenticateResult = Result.success(secondFreshSessionTokens)
        let actualSecondSessionTokens = try await sut()

        #expect(actualFirstSessionTokens == firstFreshSessionTokens)
        #expect(actualSecondSessionTokens == secondFreshSessionTokens)
        #expect(authenticationClient.receivedMessages == [
            .requestCipheredNonce, .authenticate(expectedRequest),
            .requestCipheredNonce, .authenticate(expectedRequest),
        ])
    }

    @Test
    func renewSessionTokensCoalescesConcurrentFailures() async throws {
        let authenticationClient = SpySessionAuthenticationClient()
        authenticationClient.requestCipheredNonceResult = Result.success("any ciphered nonce")
        authenticationClient.authenticateResult = Result.failure(.authenticationRejected)

        let nonceDecryptor = SpyNonceDecryptor()
        let expectedDecryptedNonce = "any decrypted nonce"
        nonceDecryptor.decryptResult = Result.success(Data(expectedDecryptedNonce.utf8))

        let expectedDevicePrivateKey = SpyDevicePrivateKey.successStub
        let devicePrivateKeyRepository = SpyDevicePrivateKeyRepository()
        devicePrivateKeyRepository.retrieveResult = Result.success(expectedDevicePrivateKey)

        let expectedRequest = try SessionAuthenticationRequest.fake(
            devicePrivateKey: expectedDevicePrivateKey,
            decryptedNonce: expectedDecryptedNonce,
            appAttestToken: nil
        )

        let sut = makeSUT(
            sessionAuthenticationClient: authenticationClient,
            sessionTokensRepository: .successStub,
            devicePrivateKeyRepository: devicePrivateKeyRepository,
            nonceDecryptor: nonceDecryptor
        )

        async let firstResult = Self.attemptRenewal(with: sut)
        async let secondResult = Self.attemptRenewal(with: sut)
        async let thirdResult = Self.attemptRenewal(with: sut)

        let (actualFirstResult, actualSecondResult, actualThirdResult) = await (firstResult, secondResult, thirdResult)

        for actualResult in [actualFirstResult, actualSecondResult, actualThirdResult] {
            guard case .failure(.clientFailure(.authenticationRejected)) = actualResult else {
                Issue.record("Expected .clientFailure(.authenticationRejected), got \(actualResult)")
                continue
            }
        }

        #expect(authenticationClient.receivedMessages == [.requestCipheredNonce, .authenticate(expectedRequest)])

        let freshSessionTokensAfterAuthentication = SessionTokens.uniqueFake()
        authenticationClient.authenticateResult = Result.success(freshSessionTokensAfterAuthentication)

        let actualSessionTokens = try await sut()

        #expect(actualSessionTokens == freshSessionTokensAfterAuthentication)
        #expect(authenticationClient.receivedMessages == [
            .requestCipheredNonce, .authenticate(expectedRequest),
            .requestCipheredNonce, .authenticate(expectedRequest),
        ])
    }
}

// MARK: - Factory methods

extension RenewSessionTokensUseCaseTests {
    private func makeSUT(
        registerDevice: @escaping RegisterDevice = { nil },
        appAttestService: some AppAttestService = SpyAppAttestService(),
        appAttestationStatusRepository: some AppAttestationStatusRepository = SpyAppAttestationStatusRepository(),
        sessionAuthenticationClient: some SessionAuthenticationClient = SpySessionAuthenticationClient(),
        sessionTokensRepository: some SessionTokensRepository = SpySessionTokensRepository(),
        deviceRegistrationStatusRepository: some DeviceRegistrationStatusRepository = SpyDeviceRegistrationStatusRepository(),
        userWalletRegistrationStatusRepository: some UserWalletRegistrationStatusRepository = SpyUserWalletRegistrationStatusRepository(),
        devicePrivateKeyRepository: some DevicePrivateKeyRepository = SpyDevicePrivateKeyRepository(),
        nonceDecryptor: some NonceDecryptor = SpyNonceDecryptor(),
        dateProvider: @escaping @autoclosure @Sendable () -> Date = Date.now,
        analyticsReporter: some BackendAuthenticationNonceAnalyticsReporter = SpyBackendAuthenticationNonceAnalyticsReporter(),
        sourceLocation: SourceLocation = #_sourceLocation
    ) -> RenewSessionTokensUseCase {
        trackForMemoryLeaks(
            RenewSessionTokensUseCase(
                registerDevice: registerDevice,
                appAttestService: appAttestService,
                sessionAuthenticationClient: sessionAuthenticationClient,
                sessionTokensRepository: sessionTokensRepository,
                appAttestationStatusRepository: appAttestationStatusRepository,
                deviceRegistrationStatusRepository: deviceRegistrationStatusRepository,
                userWalletRegistrationStatusRepository: userWalletRegistrationStatusRepository,
                deviceKeyManager: DeviceKeyManager(privateKeyRepository: devicePrivateKeyRepository),
                nonceDecryptor: nonceDecryptor,
                deviceMetadataProvider: DeviceMetadata.fake,
                dateProvider: dateProvider(),
                analyticsReporter: analyticsReporter,
                logger: Logger(category: OSLogCategory(name: "Tests"))
            ),
            sourceLocation: sourceLocation
        )
    }

    private static func attemptRenewal(with sut: RenewSessionTokensUseCase) async -> Result<SessionTokens, RenewSessionTokensError> {
        do throws(RenewSessionTokensError) {
            return .success(try await sut())
        } catch {
            return .failure(error)
        }
    }
}
