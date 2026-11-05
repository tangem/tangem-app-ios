//
//  DeviceKeyManagerTests.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import CryptoKit
import Foundation
import Testing
import TangemTestKit
@testable import TangemBackendAuthentication

@Suite(.tags(.backendAuthentication))
final class DeviceKeyManagerTests: LeakTrackingTestSuite {
    @Test
    func publicKeyIsCachedAcrossRepeatedAccess() async throws {
        let sut = makeSUT()

        let firstAccess = try await sut.publicKey
        let secondAccess = try await sut.publicKey

        #expect(firstAccess == secondAccess)
    }

    @Test
    func signProducesValidSignatureForThePublicKey() async throws {
        let sut = makeSUT()
        let anyData = Data("any payload to sign".utf8)

        let publicKey = try await sut.publicKey
        let signature = try await sut.sign(data: anyData)

        let cryptoKitPublicKey = try P256.Signing.PublicKey(x963Representation: publicKey.rawPoint)
        let cryptoKitSignature = try P256.Signing.ECDSASignature(rawRepresentation: signature.rawRepresentation)

        #expect(cryptoKitPublicKey.isValidSignature(cryptoKitSignature, for: anyData))
    }

    @Test
    func privateKeyRepositoryIsAccessedExactlyOnceUnderConcurrentAccess() async throws {
        let spyPrivateKeyProvider = SpyDevicePrivateKeyRepository()
        spyPrivateKeyProvider.retrieveResult = Result.success(.successStub)
        let sut = makeSUT(privateKeyRepository: spyPrivateKeyProvider)

        async let first = sut.publicKey
        async let second = sut.sign(data: Data())
        async let third = sut.publicKey

        _ = try await first
        _ = try await second
        _ = try await third

        #expect(spyPrivateKeyProvider.receivedMessages == [.retrieve])
    }

    @Test
    func failedPrivateKeyRecoversAfterSuccessfulRetry() async throws {
        let repository = SpyDevicePrivateKeyRepository()
        repository.retrieveResult = .failure(.keychainFailure(.itemCorrupted))

        let sut = makeSUT(privateKeyRepository: repository)

        let firstError = try await #require(throws: DeviceKeyManagerError.self) {
            _ = try await sut.publicKey
        }

        guard case .privateKeyUnavailable(.keychainFailure(.itemCorrupted)) = firstError else {
            Issue.record("Expected .privateKeyUnavailable(.keychainFailure(.itemCorrupted)), got \(firstError)")
            return
        }

        #expect(repository.receivedMessages == [.retrieve])

        let expectedPrivateKey = SpyDevicePrivateKey.successStub
        repository.retrieveResult = .success(expectedPrivateKey)

        let recoveredPublicKey = try await sut.publicKey

        #expect(try recoveredPublicKey == expectedPrivateKey.publicKey)
        #expect(repository.receivedMessages == [.retrieve, .retrieve])
    }

    @Test
    func publicKeyAccessPropagatesPublicKeyConstructionFailure() async throws {
        let rawPointFormatError = DevicePublicKey.RawPointFormatError.invalidLength(actual: 0)
        let devicePrivateKey = SpyDevicePrivateKey.successStub
        devicePrivateKey.publicKeyResult = Result.failure(rawPointFormatError)

        let privateKeyRepository = SpyDevicePrivateKeyRepository()
        privateKeyRepository.retrieveResult = Result.success(devicePrivateKey)

        let sut = makeSUT(privateKeyRepository: privateKeyRepository)

        let deviceKeyManagerError = try await #require(throws: DeviceKeyManagerError.self) {
            _ = try await sut.publicKey
        }

        guard case .publicKeyConstructionFailed(rawPointFormatError) = deviceKeyManagerError else {
            Issue.record("Expected .publicKeyConstructionFailed(\(rawPointFormatError), got \(deviceKeyManagerError)")
            return
        }
    }

    @Test
    func signPropagatesSigningFailure() async throws {
        let devicePrivateKey = SpyDevicePrivateKey()
        let expectedSignError = AnyTestError()
        devicePrivateKey.signResult = Result.failure(expectedSignError)

        let privateKeyRepository = SpyDevicePrivateKeyRepository()
        privateKeyRepository.retrieveResult = Result.success(devicePrivateKey)

        let sut = makeSUT(privateKeyRepository: privateKeyRepository)
        let expectedDataToSign = Data("some data to sign".utf8)

        let deviceKeyManagerError = try await #require(throws: DeviceKeyManagerError.self) {
            _ = try await sut.sign(data: expectedDataToSign)
        }

        guard case .signingFailed(underlying: expectedSignError) = deviceKeyManagerError else {
            Issue.record("Expected .signingFailed(SigningError.stub), got \(deviceKeyManagerError)")
            return
        }

        #expect(devicePrivateKey.receivedMessages == [.signature(expectedDataToSign)])
    }

    @Test
    func deleteKeyMakesNextPublicKeyAccessReloadPrivateKey() async throws {
        let privateKeyRepository = SpyDevicePrivateKeyRepository()
        privateKeyRepository.retrieveResult = Result.success(.successStub)
        privateKeyRepository.deleteResult = Result.success(())

        let sut = makeSUT(privateKeyRepository: privateKeyRepository)
        _ = try await sut.publicKey

        try await sut.deleteKey()

        let reloadedPrivateKey = SpyDevicePrivateKey.successStub
        privateKeyRepository.retrieveResult = Result.success(reloadedPrivateKey)

        let publicKeyAfterDeletion = try await sut.publicKey

        #expect(try publicKeyAfterDeletion == reloadedPrivateKey.publicKeyResult.get())
        #expect(privateKeyRepository.receivedMessages == [.retrieve, .delete, .retrieve])
    }

    @Test
    func failedDeleteKeyStillMakesNextPublicKeyAccessReloadPrivateKey() async throws {
        let keychainDeletionError = KeychainRepositoryError.deleteFailed(status: 67)

        let privateKeyRepository = SpyDevicePrivateKeyRepository()
        privateKeyRepository.retrieveResult = Result.success(.successStub)
        privateKeyRepository.deleteResult = Result.failure(.keychainFailure(keychainDeletionError))

        let sut = makeSUT(privateKeyRepository: privateKeyRepository)
        _ = try await sut.publicKey

        let deviceKeyManagerError = try await #require(throws: DeviceKeyManagerError.self) {
            try await sut.deleteKey()
        }

        guard case .privateKeyDeletionFailed(.keychainFailure(keychainDeletionError)) = deviceKeyManagerError else {
            Issue.record(
                "Expected .privateKeyDeletionFailed(.keychainFailure(\(keychainDeletionError))), got \(deviceKeyManagerError)"
            )
            return
        }

        let reloadedPrivateKey = SpyDevicePrivateKey.successStub
        privateKeyRepository.retrieveResult = Result.success(reloadedPrivateKey)

        let publicKeyAfterFailedDeletion = try await sut.publicKey

        #expect(try publicKeyAfterFailedDeletion == reloadedPrivateKey.publicKeyResult.get())
        #expect(privateKeyRepository.receivedMessages == [.retrieve, .delete, .retrieve])
    }

    @Test
    func failedDeleteKeyStillMakesNextSignReloadPrivateKey() async throws {
        let keychainDeletionError = KeychainRepositoryError.deleteFailed(status: 42)

        let privateKeyRepository = SpyDevicePrivateKeyRepository()
        privateKeyRepository.retrieveResult = Result.success(.successStub)
        privateKeyRepository.deleteResult = Result.failure(.keychainFailure(keychainDeletionError))

        let sut = makeSUT(privateKeyRepository: privateKeyRepository)
        _ = try await sut.sign(data: Data("any payload to sign".utf8))

        let deviceKeyManagerError = try await #require(throws: DeviceKeyManagerError.self) {
            try await sut.deleteKey()
        }

        guard case .privateKeyDeletionFailed(.keychainFailure(keychainDeletionError)) = deviceKeyManagerError else {
            Issue.record(
                "Expected .privateKeyDeletionFailed(.keychainFailure(\(keychainDeletionError))), got \(deviceKeyManagerError)"
            )
            return
        }

        let reloadedPrivateKey = SpyDevicePrivateKey.successStub
        privateKeyRepository.retrieveResult = Result.success(reloadedPrivateKey)

        let anotherPayload = Data("another payload for signing".utf8)
        _ = try await sut.sign(data: anotherPayload)

        #expect(reloadedPrivateKey.receivedMessages == [.signature(anotherPayload)])
        #expect(privateKeyRepository.receivedMessages == [.retrieve, .delete, .retrieve])
    }
}

// MARK: - Factory methods

extension DeviceKeyManagerTests {
    private func makeSUT(
        privateKeyRepository: some DevicePrivateKeyRepository = FakeDevicePrivateKeyRepository(),
        sourceLocation: SourceLocation = #_sourceLocation
    ) -> DeviceKeyManager {
        trackForMemoryLeaks(DeviceKeyManager(privateKeyRepository: privateKeyRepository), sourceLocation: sourceLocation)
    }
}

private enum SigningError: Error {
    case stub
}
