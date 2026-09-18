//
//  RenewSessionTokensUseCaseTests.swift
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

        let expectedSessionTokens = SessionTokens.fake

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
        let expectedAttestationToken = Data("some attestation token".utf8)
        appAttestService.generateAttestationTokenResult = Result.success(expectedAttestationToken)

        let authenticationClient = SpySessionAuthenticationClient()
        let expectedCipheredNonce = "some ciphered nonce"
        let expectedSessionTokens = SessionTokens.fake
        authenticationClient.requestCipheredNonceResult = Result.success(expectedCipheredNonce)
        authenticationClient.authenticateResult = Result.success(expectedSessionTokens)

        let tokensRepository = SpySessionTokensRepository()
        tokensRepository.retrieveResult = Result.success(nil)
        tokensRepository.persistResult = Result.success(())

        let nonceDecryptor = SpyNonceDecryptor()
        let expectedDecryptedNonceBytes = Data("some decrypted nonce".utf8)
        nonceDecryptor.decryptResult = Result.success(expectedDecryptedNonceBytes)

        let sut = makeSUT(
            appAttestService: appAttestService,
            sessionAuthenticationClient: authenticationClient,
            sessionTokensRepository: tokensRepository,
            devicePrivateKeyRepository: .successStub,
            nonceDecryptor: nonceDecryptor
        )

        let actualSessionTokens = try await sut()

        #expect(actualSessionTokens == expectedSessionTokens)
        #expect(authenticationClient.receivedMessages == [
            .requestCipheredNonce,
            .authenticate(expectedAttestationToken),
        ])
        #expect(nonceDecryptor.receivedMessages == [.decrypt(expectedCipheredNonce)])
        #expect(appAttestService.receivedMessages == [.generateAttestationToken(expectedDecryptedNonceBytes)])
        #expect(tokensRepository.receivedMessages == [.retrieve, .persist(expectedSessionTokens)])
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

        let expectedSessionTokens = SessionTokens.fake

        let authenticationClient = SpySessionAuthenticationClient()
        authenticationClient.requestCipheredNonceResult = Result.success("any ciphered nonce")
        authenticationClient.authenticateResult = Result.success(expectedSessionTokens)

        let tokensRepository = SpySessionTokensRepository()
        tokensRepository.retrieveResult = Result.success(expiredCachedSessionTokens)
        tokensRepository.persistResult = Result.success(())

        let sut = makeSUT(
            sessionAuthenticationClient: authenticationClient,
            sessionTokensRepository: tokensRepository,
            devicePrivateKeyRepository: .successStub,
            nonceDecryptor: .successStub,
            dateProvider: dateNow
        )

        let actualSessionTokens = try await sut()

        #expect(actualSessionTokens == expectedSessionTokens)
        #expect(authenticationClient.receivedMessages == [.requestCipheredNonce, .authenticate(nil)])
    }

    @Test
    func renewSessionTokensFallsBackToAuthenticateWhenCachedTokensHaveNoRefreshToken() async throws {
        let cachedSessionTokensWithoutRefreshToken = SessionTokens(
            accessToken: SessionTokens.Token(jwt: "stale-access-jwt", expiresAt: Date.now),
            refreshToken: nil,
            userWalletIDs: []
        )

        let expectedSessionTokens = SessionTokens.fake

        let authenticationClient = SpySessionAuthenticationClient()
        authenticationClient.requestCipheredNonceResult = Result.success("any ciphered nonce")
        authenticationClient.authenticateResult = Result.success(expectedSessionTokens)

        let tokensRepository = SpySessionTokensRepository()
        tokensRepository.retrieveResult = Result.success(cachedSessionTokensWithoutRefreshToken)
        tokensRepository.persistResult = Result.success(())

        let sut = makeSUT(
            sessionAuthenticationClient: authenticationClient,
            sessionTokensRepository: tokensRepository,
            devicePrivateKeyRepository: .successStub,
            nonceDecryptor: .successStub
        )

        let actualSessionTokens = try await sut()

        #expect(actualSessionTokens == expectedSessionTokens)
        #expect(authenticationClient.receivedMessages == [.requestCipheredNonce, .authenticate(nil)])
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

        let expectedSessionTokens = SessionTokens.fake

        let authenticationClient = SpySessionAuthenticationClient()
        authenticationClient.refreshResult = Result.failure(.refreshFailed(underlying: AnyTestError()))
        authenticationClient.requestCipheredNonceResult = Result.success("any ciphered nonce")
        authenticationClient.authenticateResult = Result.success(expectedSessionTokens)

        let tokensRepository = SpySessionTokensRepository()
        tokensRepository.retrieveResult = Result.success(cachedSessionTokens)
        tokensRepository.persistResult = Result.success(())

        let sut = makeSUT(
            sessionAuthenticationClient: authenticationClient,
            sessionTokensRepository: tokensRepository,
            devicePrivateKeyRepository: .successStub,
            nonceDecryptor: .successStub,
            dateProvider: dateNow
        )

        let actualSessionTokens = try await sut()

        #expect(actualSessionTokens == expectedSessionTokens)
        #expect(authenticationClient.receivedMessages == [.refresh, .requestCipheredNonce, .authenticate(nil)])
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
    func renewSessionTokensReusesTokensFromRegistrationOnDeviceRegistrationMissingError() async throws {
        let tokensFromRegistration = SessionTokens.fake

        let authenticationClient = SpySessionAuthenticationClient()
        authenticationClient.requestCipheredNonceResult = Result.success("any ciphered nonce")
        authenticationClient.authenticateResult = Result.failure(.deviceRegistrationMissing)

        let tokensRepository = SpySessionTokensRepository()
        tokensRepository.retrieveResult = Result.success(nil)
        tokensRepository.persistResult = Result.success(())

        let sut = makeSUT(
            registerDevice: { tokensFromRegistration },
            sessionAuthenticationClient: authenticationClient,
            sessionTokensRepository: tokensRepository,
            devicePrivateKeyRepository: .successStub,
            nonceDecryptor: .successStub
        )

        let actualSessionTokens = try await sut()

        #expect(actualSessionTokens == tokensFromRegistration)
        #expect(authenticationClient.receivedMessages == [.requestCipheredNonce, .authenticate(nil)])
        #expect(tokensRepository.receivedMessages == [.retrieve, .persist(tokensFromRegistration)])
    }

    @Test
    func renewSessionTokensRetriesAuthenticateOnceWhenDeviceAlreadyRegistered() async throws {
        let expectedSessionTokens = SessionTokens.fake

        let authenticationClient = SpySessionAuthenticationClient()
        authenticationClient.requestCipheredNonceResult = Result.success("any ciphered nonce")
        authenticationClient.authenticateResult = Result.failure(.deviceRegistrationMissing)

        let tokensRepository = SpySessionTokensRepository()
        tokensRepository.retrieveResult = Result.success(nil)
        tokensRepository.persistResult = Result.success(())

        let sut = makeSUT(
            registerDevice: {
                authenticationClient.authenticateResult = Result.success(expectedSessionTokens)
                return nil
            },
            sessionAuthenticationClient: authenticationClient,
            sessionTokensRepository: tokensRepository,
            devicePrivateKeyRepository: .successStub,
            nonceDecryptor: .successStub
        )

        let actualSessionTokens = try await sut()

        #expect(actualSessionTokens == expectedSessionTokens)
        #expect(authenticationClient.receivedMessages == [
            .requestCipheredNonce, .authenticate(nil),
            .requestCipheredNonce, .authenticate(nil),
        ])
        #expect(tokensRepository.receivedMessages == [.retrieve, .persist(expectedSessionTokens)])
    }

    @Test
    func renewSessionTokensPropagatesSecondAuthenticationFailureWithNoFurtherRecovery() async throws {
        let authenticationClient = SpySessionAuthenticationClient()
        authenticationClient.requestCipheredNonceResult = Result.success("any ciphered nonce")
        authenticationClient.authenticateResult = Result.failure(.deviceRegistrationMissing)

        let tokensRepository = SpySessionTokensRepository()
        tokensRepository.retrieveResult = Result.success(nil)

        let sut = makeSUT(
            sessionAuthenticationClient: authenticationClient,
            sessionTokensRepository: tokensRepository,
            devicePrivateKeyRepository: .successStub,
            nonceDecryptor: .successStub
        )

        let actualError = try await #require(throws: RenewSessionTokensError.self) {
            _ = try await sut()
        }

        guard case .clientFailure(.deviceRegistrationMissing) = actualError else {
            Issue.record("Expected .clientFailure(.deviceRegistrationMissing), got \(actualError)")
            return
        }

        #expect(authenticationClient.receivedMessages == [
            .requestCipheredNonce, .authenticate(nil),
            .requestCipheredNonce, .authenticate(nil),
        ])
        #expect(tokensRepository.receivedMessages == [.retrieve])
    }

    @Test
    func renewSessionTokensPropagatesRegistrationFailure() async throws {
        let authenticationClient = SpySessionAuthenticationClient()
        authenticationClient.requestCipheredNonceResult = Result.success("any ciphered nonce")
        authenticationClient.authenticateResult = Result.failure(.deviceRegistrationMissing)

        let tokensRepository = SpySessionTokensRepository()
        tokensRepository.retrieveResult = Result.success(nil)

        let sut = makeSUT(
            registerDevice: { () throws(RegisterDeviceError) -> SessionTokens? in
                throw RegisterDeviceError.repositoryFailure(.encodingFailed)
            },
            sessionAuthenticationClient: authenticationClient,
            sessionTokensRepository: tokensRepository,
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

        #expect(tokensRepository.receivedMessages == [.retrieve])
    }

    @Test
    func renewSessionTokensSucceedsEvenWhenAttestationFails() async throws {
        let authenticationClient = SpySessionAuthenticationClient()
        let expectedSessionTokens = SessionTokens.fake
        authenticationClient.requestCipheredNonceResult = Result.success("any ciphered nonce")
        authenticationClient.authenticateResult = Result.success(expectedSessionTokens)

        let sut = makeSUT(
            sessionAuthenticationClient: authenticationClient,
            sessionTokensRepository: .successStub,
            devicePrivateKeyRepository: .successStub,
            nonceDecryptor: .successStub
        )

        let actualSessionTokens = try await sut()

        #expect(actualSessionTokens == expectedSessionTokens)
        #expect(authenticationClient.receivedMessages == [.requestCipheredNonce, .authenticate(nil)])
    }

    @Test
    func renewSessionTokensPassesAttestationTokenWhenAvailable() async throws {
        let appAttestService = SpyAppAttestService()
        let expectedAttestationToken = Data([0xAA, 0xBB])
        appAttestService.generateAttestationTokenResult = Result.success(expectedAttestationToken)

        let authenticationClient = SpySessionAuthenticationClient()
        authenticationClient.requestCipheredNonceResult = Result.success("any ciphered nonce")
        authenticationClient.authenticateResult = Result.success(SessionTokens.fake)

        let sut = makeSUT(
            appAttestService: appAttestService,
            sessionAuthenticationClient: authenticationClient,
            sessionTokensRepository: .successStub,
            devicePrivateKeyRepository: .successStub,
            nonceDecryptor: .successStub
        )

        _ = try await sut()

        #expect(authenticationClient.receivedMessages == [.requestCipheredNonce, .authenticate(expectedAttestationToken)])
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
        let expectedAttestationToken = Data("some attestation token".utf8)
        appAttestService.generateAttestationTokenResult = Result.success(expectedAttestationToken)

        let authenticationClient = SpySessionAuthenticationClient()
        let expectedCipheredNonce = "some ciphered nonce"
        let expectedSessionTokens = SessionTokens.fake
        authenticationClient.requestCipheredNonceResult = Result.success(expectedCipheredNonce)
        authenticationClient.authenticateResult = Result.success(expectedSessionTokens)

        let tokensRepository = SpySessionTokensRepository()
        tokensRepository.retrieveResult = Result.success(nil)
        tokensRepository.persistResult = Result.failure(.encodingFailed)

        let nonceDecryptor = SpyNonceDecryptor()
        let expectedDecryptedNonceBytes = Data("some decrypted nonce".utf8)
        nonceDecryptor.decryptResult = Result.success(expectedDecryptedNonceBytes)

        let sut = makeSUT(
            appAttestService: appAttestService,
            sessionAuthenticationClient: authenticationClient,
            sessionTokensRepository: tokensRepository,
            devicePrivateKeyRepository: .successStub,
            nonceDecryptor: nonceDecryptor
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
            .authenticate(expectedAttestationToken),
        ])
        #expect(nonceDecryptor.receivedMessages == [.decrypt(expectedCipheredNonce)])
        #expect(appAttestService.receivedMessages == [.generateAttestationToken(expectedDecryptedNonceBytes)])
        #expect(tokensRepository.receivedMessages == [.retrieve, .persist(expectedSessionTokens)])
    }

    @Test
    func renewSessionTokensCoalescesConcurrentCalls() async throws {
        let expectedSessionTokens = SessionTokens.fake

        let authenticationClient = SpySessionAuthenticationClient()
        authenticationClient.requestCipheredNonceResult = Result.success("any ciphered nonce")
        authenticationClient.authenticateResult = Result.success(expectedSessionTokens)

        let sut = makeSUT(
            sessionAuthenticationClient: authenticationClient,
            sessionTokensRepository: .successStub,
            devicePrivateKeyRepository: .successStub,
            nonceDecryptor: .successStub
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
        #expect(authenticationClient.receivedMessages == [.requestCipheredNonce, .authenticate(nil)])
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

        let sut = makeSUT(
            sessionAuthenticationClient: authenticationClient,
            sessionTokensRepository: .successStub,
            devicePrivateKeyRepository: .successStub,
            nonceDecryptor: .successStub,
            dateProvider: dateNow
        )

        let actualFirstSessionTokens = try await sut()

        authenticationClient.authenticateResult = Result.success(secondFreshSessionTokens)
        let actualSecondSessionTokens = try await sut()

        #expect(actualFirstSessionTokens == firstFreshSessionTokens)
        #expect(actualSecondSessionTokens == secondFreshSessionTokens)
        #expect(authenticationClient.receivedMessages == [
            .requestCipheredNonce, .authenticate(nil),
            .requestCipheredNonce, .authenticate(nil),
        ])
    }

    @Test
    func renewSessionTokensCoalescesConcurrentFailures() async throws {
        let authenticationClient = SpySessionAuthenticationClient()
        authenticationClient.requestCipheredNonceResult = Result.success("any ciphered nonce")
        authenticationClient.authenticateResult = Result.failure(.authenticationRejected)

        let sut = makeSUT(
            sessionAuthenticationClient: authenticationClient,
            sessionTokensRepository: .successStub,
            devicePrivateKeyRepository: .successStub,
            nonceDecryptor: .successStub
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

        #expect(authenticationClient.receivedMessages == [.requestCipheredNonce, .authenticate(nil)])

        let freshSessionTokensAfterAuthentication = SessionTokens.fake
        authenticationClient.authenticateResult = Result.success(freshSessionTokensAfterAuthentication)

        let actualSessionTokens = try await sut()

        #expect(actualSessionTokens == freshSessionTokensAfterAuthentication)
        #expect(authenticationClient.receivedMessages == [
            .requestCipheredNonce, .authenticate(nil),
            .requestCipheredNonce, .authenticate(nil),
        ])
    }
}

// MARK: - Factory methods

extension RenewSessionTokensUseCaseTests {
    private func makeSUT(
        registerDevice: @escaping RegisterDevice = { nil },
        appAttestService: some AppAttestService = SpyAppAttestService(),
        sessionAuthenticationClient: some SessionAuthenticationClient = SpySessionAuthenticationClient(),
        sessionTokensRepository: some SessionTokensRepository = SpySessionTokensRepository(),
        devicePrivateKeyRepository: some DevicePrivateKeyRepository = SpyDevicePrivateKeyRepository(),
        nonceDecryptor: some NonceDecryptor = SpyNonceDecryptor(),
        dateProvider: @escaping @autoclosure @Sendable () -> Date = Date.now,
        sourceLocation: SourceLocation = #_sourceLocation
    ) -> RenewSessionTokensUseCase {
        trackForMemoryLeaks(
            RenewSessionTokensUseCase(
                registerDevice: registerDevice,
                appAttestService: appAttestService,
                sessionAuthenticationClient: sessionAuthenticationClient,
                sessionTokensRepository: sessionTokensRepository,
                deviceKeyManager: DeviceKeyManager(privateKeyRepository: devicePrivateKeyRepository),
                nonceDecryptor: nonceDecryptor,
                deviceMetadataProvider: .fake,
                dateProvider: dateProvider()
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
