//
//  RenewSessionTokensUseCaseTests.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import TangemBackendAuthentication

@Suite(.tags(.backendAuthentication))
struct RenewSessionTokensUseCaseTests {
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

        let expectedSessionTokens = SessionTokens.stub

        let authenticationClient = SpySessionAuthenticationClient(refreshResult: .success(expectedSessionTokens))
        let tokensRepository = SpySessionTokensRepository(retrieveResult: .success(cachedSessionTokens))

        let sut = Self.makeSUT(
            sessionAuthenticationClient: authenticationClient,
            sessionTokensRepository: tokensRepository,
            dateProvider: dateNow
        )

        let actualSessionTokens = try await sut()

        #expect(actualSessionTokens == expectedSessionTokens)
        #expect(authenticationClient.receivedMessages == [.refresh])
        #expect(tokensRepository.receivedMessages == [.retrieve, .persist(expectedSessionTokens)])
    }

    @Test
    func renewSessionTokensFallsBackToAuthenticateWhenNoCachedTokens() async throws {
        let expectedAttestationToken = StubAppAttestService.stubbedAttestationToken
        let expectedSessionTokens = SessionTokens.stub

        let authenticationClient = SpySessionAuthenticationClient(authenticateResult: .success(expectedSessionTokens))
        let tokensRepository = SpySessionTokensRepository(retrieveResult: .success(nil))

        let sut = Self.makeSUT(
            sessionAuthenticationClient: authenticationClient,
            sessionTokensRepository: tokensRepository,
            dateProvider: Date.now
        )

        let actualSessionTokens = try await sut()

        #expect(actualSessionTokens == expectedSessionTokens)
        #expect(authenticationClient.receivedMessages == [.requestCipheredNonce, .authenticate(expectedAttestationToken)])
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

        let expectedAttestationToken = StubAppAttestService.stubbedAttestationToken
        let expectedSessionTokens = SessionTokens.stub

        let authenticationClient = SpySessionAuthenticationClient(authenticateResult: .success(expectedSessionTokens))
        let tokensRepository = SpySessionTokensRepository(retrieveResult: .success(expiredCachedSessionTokens))

        let sut = Self.makeSUT(
            sessionAuthenticationClient: authenticationClient,
            sessionTokensRepository: tokensRepository,
            dateProvider: dateNow
        )

        let actualSessionTokens = try await sut()

        #expect(actualSessionTokens == expectedSessionTokens)
        #expect(authenticationClient.receivedMessages == [.requestCipheredNonce, .authenticate(expectedAttestationToken)])
        #expect(tokensRepository.receivedMessages == [.retrieve, .persist(expectedSessionTokens)])
    }

    @Test
    func renewSessionTokensFallsBackToAuthenticateWhenCachedTokensHaveNoRefreshToken() async throws {
        let cachedSessionTokensWithoutRefreshToken = SessionTokens(
            accessToken: SessionTokens.Token(jwt: "stale-access-jwt", expiresAt: Date.now),
            refreshToken: nil,
            userWalletIDs: []
        )

        let expectedAttestationToken = StubAppAttestService.stubbedAttestationToken
        let expectedSessionTokens = SessionTokens.stub

        let authenticationClient = SpySessionAuthenticationClient(authenticateResult: .success(expectedSessionTokens))
        let tokensRepository = SpySessionTokensRepository(retrieveResult: .success(cachedSessionTokensWithoutRefreshToken))

        let sut = Self.makeSUT(
            sessionAuthenticationClient: authenticationClient,
            sessionTokensRepository: tokensRepository,
            dateProvider: Date.now
        )

        let actualSessionTokens = try await sut()

        #expect(actualSessionTokens == expectedSessionTokens)
        #expect(authenticationClient.receivedMessages == [.requestCipheredNonce, .authenticate(expectedAttestationToken)])
        #expect(tokensRepository.receivedMessages == [.retrieve, .persist(expectedSessionTokens)])
    }

    @Test
    func renewSessionTokensPropagatesRepositoryFailureWhenRetrieveFails() async throws {
        let authenticationClient = SpySessionAuthenticationClient()
        let tokensRepository = SpySessionTokensRepository(retrieveResult: .failure(.decodingFailed))

        let sut = Self.makeSUT(
            sessionAuthenticationClient: authenticationClient,
            sessionTokensRepository: tokensRepository,
            dateProvider: Date.now
        )

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
    func renewSessionTokensFallsBackToAuthenticateWhenRefreshCallFails() async throws {
        let dateNow = Date.now
        let twentyMinutesAfter = dateNow.addingTimeInterval(60 * 20)

        let cachedSessionTokens = SessionTokens(
            accessToken: SessionTokens.Token(jwt: "stale-access-jwt", expiresAt: dateNow),
            refreshToken: SessionTokens.Token(jwt: "valid-refresh-jwt", expiresAt: twentyMinutesAfter),
            userWalletIDs: []
        )

        let expectedAttestationToken = StubAppAttestService.stubbedAttestationToken
        let freshSessionTokensAfterAuthentication = SessionTokens.stub
        let expectedSessionTokens = freshSessionTokensAfterAuthentication

        let authenticationClient = SpySessionAuthenticationClient(
            authenticateResult: .success(freshSessionTokensAfterAuthentication),
            refreshResult: .failure(.refreshFailed(underlying: AnyTestError()))
        )
        let tokensRepository = SpySessionTokensRepository(retrieveResult: .success(cachedSessionTokens))

        let sut = Self.makeSUT(
            sessionAuthenticationClient: authenticationClient,
            sessionTokensRepository: tokensRepository,
            dateProvider: dateNow
        )

        let actualSessionTokens = try await sut()

        #expect(actualSessionTokens == expectedSessionTokens)
        #expect(authenticationClient.receivedMessages == [.refresh, .requestCipheredNonce, .authenticate(expectedAttestationToken)])
        #expect(tokensRepository.receivedMessages == [.retrieve, .persist(expectedSessionTokens)])
    }

    @Test
    func renewSessionTokensDeletesSessionTokensWhenAuthenticationRejected() async throws {
        let expectedAttestationToken = StubAppAttestService.stubbedAttestationToken
        let authenticationClient = SpySessionAuthenticationClient(authenticateResult: .failure(.authenticationRejected))
        let tokensRepository = SpySessionTokensRepository(retrieveResult: .success(nil))

        let sut = Self.makeSUT(
            sessionAuthenticationClient: authenticationClient,
            sessionTokensRepository: tokensRepository,
            dateProvider: Date.now
        )

        let actualError = try await #require(throws: RenewSessionTokensError.self) {
            _ = try await sut()
        }

        guard case .clientFailure(.authenticationRejected) = actualError else {
            Issue.record("Expected .clientFailure(.authenticationRejected), got \(actualError)")
            return
        }

        #expect(authenticationClient.receivedMessages == [.requestCipheredNonce, .authenticate(expectedAttestationToken)])
        #expect(tokensRepository.receivedMessages == [.retrieve, .delete])
    }

    @Test
    func renewSessionTokensPropagatesAuthenticationRejectedEvenWhenDeleteFails() async throws {
        let authenticationClient = SpySessionAuthenticationClient(authenticateResult: .failure(.authenticationRejected))
        let tokensRepository = SpySessionTokensRepository(
            retrieveResult: .success(nil),
            deleteResult: .failure(.keychainFailure(.deleteFailed(status: -1)))
        )

        let sut = Self.makeSUT(
            sessionAuthenticationClient: authenticationClient,
            sessionTokensRepository: tokensRepository,
            dateProvider: Date.now
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
        let authenticationClient = SpySessionAuthenticationClient(
            requestCipheredNonceResult: .failure(.requestNonceFailed(underlying: AnyTestError()))
        )
        let tokensRepository = SpySessionTokensRepository(retrieveResult: .success(nil))

        let sut = Self.makeSUT(
            sessionAuthenticationClient: authenticationClient,
            sessionTokensRepository: tokensRepository,
            dateProvider: Date.now
        )

        let actualError = try await #require(throws: RenewSessionTokensError.self) {
            _ = try await sut()
        }

        guard case .clientFailure(.requestNonceFailed) = actualError else {
            Issue.record("Expected .clientFailure(.requestNonceFailed), got \(actualError)")
            return
        }

        #expect(authenticationClient.receivedMessages == [.requestCipheredNonce])
        #expect(tokensRepository.receivedMessages == [.retrieve])
    }

    @Test
    func renewSessionTokensSucceedsEvenWhenAttestationFails() async throws {
        let expectedSessionTokens = SessionTokens.stub

        let authenticationClient = SpySessionAuthenticationClient(authenticateResult: .success(expectedSessionTokens))
        let appAttestService = StubAppAttestService(result: .failure(AppAttestServiceError()))

        let sut = Self.makeSUT(
            appAttestService: appAttestService,
            sessionAuthenticationClient: authenticationClient,
            sessionTokensRepository: SpySessionTokensRepository(retrieveResult: .success(nil)),
            dateProvider: Date.now
        )

        let actualSessionTokens = try await sut()

        #expect(actualSessionTokens == expectedSessionTokens)
        #expect(authenticationClient.receivedMessages == [.requestCipheredNonce, .authenticate(nil)])
    }

    @Test
    func renewSessionTokensPassesAttestationTokenWhenAvailable() async throws {
        let expectedAttestationToken = Data([0xAA, 0xBB])

        let authenticationClient = SpySessionAuthenticationClient(authenticateResult: .success(.stub))
        let appAttestService = StubAppAttestService(result: .success(expectedAttestationToken))

        let sut = Self.makeSUT(
            appAttestService: appAttestService,
            sessionAuthenticationClient: authenticationClient,
            sessionTokensRepository: SpySessionTokensRepository(retrieveResult: .success(nil)),
            dateProvider: Date.now
        )

        _ = try await sut()

        #expect(authenticationClient.receivedMessages == [.requestCipheredNonce, .authenticate(expectedAttestationToken)])
    }

    @Test
    func renewSessionTokensThrowsDeviceKeyFailureWhenPrivateKeyUnavailable() async throws {
        let devicePrivateKeyRepository = StubDevicePrivateKeyRepository(
            result: .failure(.keyGenerationFailed(underlying: AnyTestError()))
        )

        let sut = Self.makeSUT(
            sessionTokensRepository: SpySessionTokensRepository(retrieveResult: .success(nil)),
            devicePrivateKeyRepository: devicePrivateKeyRepository,
            dateProvider: Date.now
        )

        let actualError = try await #require(throws: RenewSessionTokensError.self) {
            _ = try await sut()
        }

        guard case .deviceKeyFailure = actualError else {
            Issue.record("Expected .deviceKeyFailure, got \(actualError)")
            return
        }
    }

    @Test
    func renewSessionTokensThrowsNonceDecryptionFailureWhenDecryptFails() async throws {
        let sut = Self.makeSUT(
            sessionTokensRepository: SpySessionTokensRepository(retrieveResult: .success(nil)),
            nonceDecryptor: StubNonceDecryptor(result: .failure(.invalidCipheredNonceEncoding)),
            dateProvider: Date.now
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
        let tokensRepository = SpySessionTokensRepository(
            retrieveResult: .success(nil),
            persistResult: .failure(.encodingFailed)
        )

        let sut = Self.makeSUT(
            sessionAuthenticationClient: SpySessionAuthenticationClient(authenticateResult: .success(.stub)),
            sessionTokensRepository: tokensRepository,
            dateProvider: Date.now
        )

        let actualError = try await #require(throws: RenewSessionTokensError.self) {
            _ = try await sut()
        }

        guard case .repositoryFailure(.encodingFailed) = actualError else {
            Issue.record("Expected .repositoryFailure(.encodingFailed), got \(actualError)")
            return
        }

        #expect(tokensRepository.receivedMessages == [.retrieve, .persist(.stub)])
    }

    @Test
    func renewSessionTokensCoalescesConcurrentCalls() async throws {
        let expectedAttestationToken = StubAppAttestService.stubbedAttestationToken
        let expectedSessionTokens = SessionTokens.stub

        let authenticationClient = SpySessionAuthenticationClient(authenticateResult: .success(expectedSessionTokens))
        let sut = Self.makeSUT(
            sessionAuthenticationClient: authenticationClient,
            sessionTokensRepository: SpySessionTokensRepository(retrieveResult: .success(nil)),
            dateProvider: Date.now
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
        #expect(authenticationClient.receivedMessages == [.requestCipheredNonce, .authenticate(expectedAttestationToken)])
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

        let expectedAttestationToken = StubAppAttestService.stubbedAttestationToken

        let authenticationClient = SpySessionAuthenticationClient(authenticateResult: .success(firstFreshSessionTokens))
        let sut = Self.makeSUT(
            sessionAuthenticationClient: authenticationClient,
            sessionTokensRepository: SpySessionTokensRepository(retrieveResult: .success(nil)),
            dateProvider: dateNow
        )

        let actualFirstSessionTokens = try await sut()

        authenticationClient.setAuthenticateResult(.success(secondFreshSessionTokens))
        let actualSecondSessionTokens = try await sut()

        #expect(actualFirstSessionTokens == firstFreshSessionTokens)
        #expect(actualSecondSessionTokens == secondFreshSessionTokens)
        #expect(authenticationClient.receivedMessages == [
            .requestCipheredNonce, .authenticate(expectedAttestationToken),
            .requestCipheredNonce, .authenticate(expectedAttestationToken),
        ])
    }

    @Test
    func renewSessionTokensCoalescesConcurrentFailures() async throws {
        let expectedAttestationToken = StubAppAttestService.stubbedAttestationToken

        let authenticationClient = SpySessionAuthenticationClient(authenticateResult: .failure(.authenticationRejected))

        let sut = Self.makeSUT(
            sessionAuthenticationClient: authenticationClient,
            sessionTokensRepository: SpySessionTokensRepository(retrieveResult: .success(nil)),
            dateProvider: Date.now
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

        #expect(authenticationClient.receivedMessages == [.requestCipheredNonce, .authenticate(expectedAttestationToken)])

        let freshSessionTokensAfterAuthentication = SessionTokens.stub
        let expectedSessionTokens = freshSessionTokensAfterAuthentication
        authenticationClient.setAuthenticateResult(.success(freshSessionTokensAfterAuthentication))

        let actualSessionTokens = try await sut()

        #expect(actualSessionTokens == expectedSessionTokens)
        #expect(authenticationClient.receivedMessages == [
            .requestCipheredNonce, .authenticate(expectedAttestationToken),
            .requestCipheredNonce, .authenticate(expectedAttestationToken),
        ])
    }
}

// MARK: - Factory methods

extension RenewSessionTokensUseCaseTests {
    private static func makeSUT(
        appAttestService: some AppAttestService = StubAppAttestService(),
        sessionAuthenticationClient: some SessionAuthenticationClient = SpySessionAuthenticationClient(),
        sessionTokensRepository: some SessionTokensRepository = SpySessionTokensRepository(),
        devicePrivateKeyRepository: some DevicePrivateKeyRepository = FakeDevicePrivateKeyRepository(),
        nonceDecryptor: some NonceDecryptor = StubNonceDecryptor(),
        dateProvider: @escaping @autoclosure @Sendable () -> Date
    ) -> RenewSessionTokensUseCase {
        return RenewSessionTokensUseCase(
            appAttestService: appAttestService,
            sessionAuthenticationClient: sessionAuthenticationClient,
            sessionTokensRepository: sessionTokensRepository,
            deviceKeyManager: DeviceKeyManager(privateKeyRepository: devicePrivateKeyRepository),
            nonceDecryptor: nonceDecryptor,
            deviceMetadataProvider: .fake,
            dateProvider: dateProvider()
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

// MARK: - Fixtures

private extension SessionTokens {
    static let stub = SessionTokens(
        accessToken: Token(jwt: "access-jwt", expiresAt: Date(timeIntervalSince1970: 2000)),
        refreshToken: Token(jwt: "refresh-jwt", expiresAt: Date(timeIntervalSince1970: 3000)),
        userWalletIDs: []
    )
}

private struct AnyTestError: Error {}
