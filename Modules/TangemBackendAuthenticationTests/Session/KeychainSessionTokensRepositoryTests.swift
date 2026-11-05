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

        try await sut.persist(tokens: Self.sampleTokens)
        let retrievedTokens = try await sut.retrieve()

        #expect(retrievedTokens == Self.sampleTokens)
    }

    @Test
    func persistThenRetrieveRoundTripsTokensWithNoRefreshTokenAndNoWallets() async throws {
        let sut = makeSUT(keychainRepository: FakeKeychainRepository())

        try await sut.persist(tokens: Self.tokensWithoutRefreshTokenOrWallets)
        let retrievedTokens = try await sut.retrieve()

        #expect(retrievedTokens == Self.tokensWithoutRefreshTokenOrWallets)
    }

    @Test
    func persistReplacesPreviouslyPersistedTokens() async throws {
        let sut = makeSUT(keychainRepository: FakeKeychainRepository())

        try await sut.persist(tokens: Self.sampleTokens)
        try await sut.persist(tokens: Self.anotherSampleTokens)
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
        let keychainRepository = SpyKeychainRepository()
        keychainRepository.retrieveResult = Result.success(malformedData)
        let sut = makeSUT(keychainRepository: keychainRepository)

        await #expect(throws: SessionTokensRepositoryError.decodingFailed) {
            _ = try await sut.retrieve()
        }

        #expect(keychainRepository.receivedMessages == [.retrieve])
    }

    @Test
    func retrieveThrowsKeychainFailureWhenKeychainRetrieveFails() async throws {
        let keychainRepository = SpyKeychainRepository()
        keychainRepository.retrieveResult = Result.failure(.itemCorrupted)
        let sut = makeSUT(keychainRepository: keychainRepository)

        await #expect(throws: SessionTokensRepositoryError.keychainFailure(.itemCorrupted)) {
            _ = try await sut.retrieve()
        }

        #expect(keychainRepository.receivedMessages == [.retrieve])
    }

    @Test
    func persistThrowsKeychainFailureWhenInsertFails() async throws {
        let insertFailsKeychainError = KeychainRepositoryError.insertFailed(status: .any)
        let keychainRepository = SpyKeychainRepository()
        keychainRepository.insertResult = Result.failure(insertFailsKeychainError)
        let sut = makeSUT(keychainRepository: keychainRepository)

        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let expectedData = try encoder.encode(
            KeychainSessionTokensRepository.VersionedDTO(
                version: 1,
                dto: KeychainSessionTokensRepository.SessionTokensDTO(fromDomain: Self.sampleTokens)
            )
        )

        await #expect(throws: SessionTokensRepositoryError.keychainFailure(insertFailsKeychainError)) {
            try await sut.persist(tokens: Self.sampleTokens)
        }

        #expect(keychainRepository.receivedMessages == [.insert(expectedData)])
    }

    @Test
    func persistThrowsKeychainFailureWhenUpdateFailsAfterInsertFindsADuplicate() async throws {
        let updateFailsKeychainError = KeychainRepositoryError.updateFailed(status: .any)
        let keychainRepository = SpyKeychainRepository()
        keychainRepository.insertResult = Result.failure(.duplicateItem)
        keychainRepository.updateResult = Result.failure(updateFailsKeychainError)
        let sut = makeSUT(keychainRepository: keychainRepository)

        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let expectedData = try encoder.encode(
            KeychainSessionTokensRepository.VersionedDTO(
                version: 1,
                dto: KeychainSessionTokensRepository.SessionTokensDTO(fromDomain: Self.sampleTokens)
            )
        )

        await #expect(throws: SessionTokensRepositoryError.keychainFailure(updateFailsKeychainError)) {
            try await sut.persist(tokens: Self.sampleTokens)
        }

        #expect(keychainRepository.receivedMessages == [.insert(expectedData), .update(expectedData)])
    }

    @Test
    func deleteForwardsToKeychainRepository() async throws {
        let sut = makeSUT(keychainRepository: FakeKeychainRepository())

        try await sut.persist(tokens: Self.sampleTokens)
        try await sut.delete()

        let retrievedTokens = try await sut.retrieve()
        #expect(retrievedTokens == nil)
    }

    @Test
    func deletePropagatesKeychainFailure() async throws {
        let deleteFailsKeychainError = KeychainRepositoryError.deleteFailed(status: .any)

        let keychainRepository = SpyKeychainRepository()
        keychainRepository.deleteResult = Result.failure(deleteFailsKeychainError)
        let sut = makeSUT(keychainRepository: keychainRepository)

        await #expect(throws: SessionTokensRepositoryError.keychainFailure(deleteFailsKeychainError)) {
            try await sut.delete()
        }

        #expect(keychainRepository.receivedMessages == [.delete])
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
