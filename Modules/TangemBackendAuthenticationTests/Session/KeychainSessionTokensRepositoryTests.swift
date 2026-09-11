//
//  KeychainSessionTokensRepositoryTests.swift
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
struct KeychainSessionTokensRepositoryTests {
    @Test
    func persistThenRetrieveRoundTripsTokens() async throws {
        let sut = makeSUT(keychainRepository: FakeKeychainRepository())

        try await sut.persist(Self.sampleTokens)
        let retrievedTokens = try await sut.retrieve()

        #expect(retrievedTokens == Self.sampleTokens)
    }

    @Test
    func persistThenRetrieveRoundTripsTokensWithNoRefreshTokenAndNoWallets() async throws {
        let sut = makeSUT(keychainRepository: FakeKeychainRepository())

        try await sut.persist(Self.tokensWithoutRefreshTokenOrWallets)
        let retrievedTokens = try await sut.retrieve()

        #expect(retrievedTokens == Self.tokensWithoutRefreshTokenOrWallets)
    }

    @Test
    func persistReplacesPreviouslyPersistedTokens() async throws {
        let sut = makeSUT(keychainRepository: FakeKeychainRepository())

        try await sut.persist(Self.sampleTokens)
        try await sut.persist(Self.anotherSampleTokens)
        let retrievedTokens = try await sut.retrieve()

        #expect(retrievedTokens == Self.anotherSampleTokens)
    }

    @Test
    func retrieveReturnsNilWhenNothingStored() async throws {
        let sut = makeSUT(keychainRepository: FakeKeychainRepository())

        let retrievedTokens = try await sut.retrieve()

        #expect(retrievedTokens == nil)
    }

    @Test
    func retrieveThrowsDecodingFailedForMalformedStoredData() async {
        let malformedData = Data("not valid json".utf8)
        let sut = makeSUT(keychainRepository: StubKeychainRepository(retrieveResult: .success(malformedData)))

        await #expect(throws: SessionTokensRepositoryError.decodingFailed) {
            _ = try await sut.retrieve()
        }
    }

    @Test
    func retrieveThrowsKeychainFailureWhenKeychainRetrieveFails() async throws {
        let sut = makeSUT(keychainRepository: StubKeychainRepository(retrieveResult: .failure(.itemCorrupted)))

        await #expect(throws: SessionTokensRepositoryError.keychainFailure(.itemCorrupted)) {
            _ = try await sut.retrieve()
        }
    }

    @Test
    func persistThrowsKeychainFailureWhenInsertFails() async throws {
        let insertFailsKeychainError = KeychainRepositoryError.insertFailed(status: .any)
        let sut = makeSUT(keychainRepository: StubKeychainRepository(insertResult: .failure(insertFailsKeychainError)))

        await #expect(throws: SessionTokensRepositoryError.keychainFailure(insertFailsKeychainError)) {
            try await sut.persist(Self.sampleTokens)
        }
    }

    @Test
    func persistThrowsKeychainFailureWhenUpdateFailsAfterInsertFindsADuplicate() async throws {
        let updateFailsKeychainError = KeychainRepositoryError.updateFailed(status: .any)
        let sut = makeSUT(
            keychainRepository: StubKeychainRepository(
                insertResult: .failure(.duplicateItem),
                updateResult: .failure(updateFailsKeychainError)
            )
        )

        await #expect(throws: SessionTokensRepositoryError.keychainFailure(updateFailsKeychainError)) {
            try await sut.persist(Self.sampleTokens)
        }
    }

    @Test
    func deleteForwardsToKeychainRepository() async throws {
        let sut = makeSUT(keychainRepository: FakeKeychainRepository())

        try await sut.persist(Self.sampleTokens)
        try await sut.delete()

        let retrievedTokens = try await sut.retrieve()
        #expect(retrievedTokens == nil)
    }

    @Test
    func deletePropagatesKeychainFailure() async throws {
        let deleteFailsKeychainError = KeychainRepositoryError.deleteFailed(status: .any)

        let sut = makeSUT(keychainRepository: StubKeychainRepository(deleteResult: .failure(deleteFailsKeychainError)))

        await #expect(throws: SessionTokensRepositoryError.keychainFailure(deleteFailsKeychainError)) {
            try await sut.delete()
        }
    }
}

// MARK: - Factory methods

extension KeychainSessionTokensRepositoryTests {
    private func makeSUT(keychainRepository: some KeychainRepository) -> KeychainSessionTokensRepository {
        KeychainSessionTokensRepository(keychainRepository: keychainRepository)
    }
}

extension KeychainSessionTokensRepositoryTests {
    private static let sampleTokens = SessionTokens(
        accessToken: SessionTokens.Token(jwt: "access-jwt", expiresAt: Date(timeIntervalSince1970: 1_700_000_000)),
        refreshToken: SessionTokens.Token(jwt: "refresh-jwt", expiresAt: Date(timeIntervalSince1970: 1_700_600_000)),
        userWalletIDs: [
            UserWalletId(value: Data([0x01, 0x02, 0x03])),
            UserWalletId(value: Data([0x04, 0x05, 0x06])),
        ]
    )

    private static let anotherSampleTokens = SessionTokens(
        accessToken: SessionTokens.Token(jwt: "another-access-jwt", expiresAt: Date(timeIntervalSince1970: 1_800_000_000)),
        refreshToken: SessionTokens.Token(jwt: "another-refresh-jwt", expiresAt: Date(timeIntervalSince1970: 1_800_600_000)),
        userWalletIDs: [UserWalletId(value: Data([0x07, 0x08, 0x09]))]
    )

    private static let tokensWithoutRefreshTokenOrWallets = SessionTokens(
        accessToken: SessionTokens.Token(jwt: "solo-access-jwt", expiresAt: Date(timeIntervalSince1970: 1_650_000_000)),
        refreshToken: nil,
        userWalletIDs: []
    )
}

private extension OSStatus {
    static let any: OSStatus = -1
}
