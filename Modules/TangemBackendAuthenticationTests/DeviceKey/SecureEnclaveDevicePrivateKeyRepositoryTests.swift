//
//  SecureEnclaveDevicePrivateKeyRepositoryTests.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import TangemBackendAuthentication

@Suite(.tags(.backendAuthentication))
struct SecureEnclaveDevicePrivateKeyRepositoryTests {
    @Test
    func retrieveGeneratesAndPersistsNewKeyWhenNoneStored() async throws {
        let keychainRepository = FakeKeychainRepository()
        let sut = makeSUT(keychainRepository: keychainRepository)

        _ = try await sut.retrieve()

        let storedData = try keychainRepository.retrieve()
        #expect(storedData != nil)
    }

    @Test
    func retrieveRestoresExistingKeyWithoutRegeneratingWhenAlreadyStored() async throws {
        let keychainRepository = FakeKeychainRepository()
        let firstSUT = makeSUT(keychainRepository: keychainRepository)
        let secondSUT = makeSUT(keychainRepository: keychainRepository)

        let firstKey = try await firstSUT.retrieve()
        let secondKey = try await secondSUT.retrieve()

        #expect(try firstKey.publicKey.rawPoint == secondKey.publicKey.rawPoint)
    }

    @Test
    func retrieveThrowsKeyRestorationFailedForCorruptedStoredData() async throws {
        let corruptedData = Data([0x00, 0x01, 0x02])
        let keychainRepository = SpyKeychainRepository()
        keychainRepository.retrieveResult = Result.success(corruptedData)
        let sut = makeSUT(keychainRepository: keychainRepository)

        let error = try await #require(throws: DevicePrivateKeyRepositoryError.self) {
            _ = try await sut.retrieve()
        }

        guard case .keyRestorationFailed = error else {
            Issue.record("Expected .keyRestorationFailed, got \(error)")
            return
        }

        #expect(keychainRepository.receivedMessages == [.retrieve])
    }

    @Test
    func retrieveThrowsKeychainFailureWhenKeychainRetrieveFails() async throws {
        let keychainRepository = SpyKeychainRepository()
        keychainRepository.retrieveResult = Result.failure(.itemCorrupted)
        let sut = makeSUT(keychainRepository: keychainRepository)

        let error = try await #require(throws: DevicePrivateKeyRepositoryError.self) {
            _ = try await sut.retrieve()
        }

        guard case .keychainFailure(.itemCorrupted) = error else {
            Issue.record("Expected .keychainFailure(.itemCorrupted), got \(error)")
            return
        }

        #expect(keychainRepository.receivedMessages == [.retrieve])
    }

    @Test
    func retrieveThrowsKeychainFailureWhenInsertFails() async throws {
        let keychainRepository = SpyKeychainRepository()
        keychainRepository.insertResult = Result.failure(.insertFailed(status: -1))
        keychainRepository.retrieveResult = Result.success(nil)
        let sut = makeSUT(keychainRepository: keychainRepository)

        let error = try await #require(throws: DevicePrivateKeyRepositoryError.self) {
            _ = try await sut.retrieve()
        }

        guard case .keychainFailure(.insertFailed(status: -1)) = error else {
            Issue.record("Expected .keychainFailure(.insertFailed(status: -1)), got \(error)")
            return
        }
    }

    @Test
    func deleteForwardsToKeychainRepository() async throws {
        let keychainRepository = FakeKeychainRepository()
        let sut = makeSUT(keychainRepository: keychainRepository)

        _ = try await sut.retrieve()
        try await sut.delete()

        let storedData = try keychainRepository.retrieve()
        #expect(storedData == nil)
    }

    @Test
    func deletePropagatesKeychainFailure() async throws {
        let keychainRepository = SpyKeychainRepository()
        keychainRepository.deleteResult = Result.failure(.deleteFailed(status: -1))
        let sut = makeSUT(keychainRepository: keychainRepository)

        let error = try await #require(throws: DevicePrivateKeyRepositoryError.self) {
            try await sut.delete()
        }

        guard case .keychainFailure(.deleteFailed(status: -1)) = error else {
            Issue.record("Expected .keychainFailure(.deleteFailed(status: -1)), got \(error)")
            return
        }

        #expect(keychainRepository.receivedMessages == [.delete])
    }
}

// MARK: - Factory methods

extension SecureEnclaveDevicePrivateKeyRepositoryTests {
    private func makeSUT(keychainRepository: some KeychainRepository) -> SecureEnclaveDevicePrivateKeyRepository {
        SecureEnclaveDevicePrivateKeyRepository(keychainRepository: keychainRepository)
    }
}
