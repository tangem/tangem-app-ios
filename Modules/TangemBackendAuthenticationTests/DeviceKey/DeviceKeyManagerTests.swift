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
        let sut = makeSUT(privateKeyRepository: spyPrivateKeyProvider)

        async let first = sut.publicKey
        async let second = sut.sign(data: Data())
        async let third = sut.publicKey

        _ = try await first
        _ = try await second
        _ = try await third

        #expect(spyPrivateKeyProvider.receivedMessages == [.privateKey])
    }

    @Test
    func failedPrivateKeyRecoversAfterSuccessfulRetry() async throws {
        let repository = SpyDevicePrivateKeyRepository()
        repository.privateKeyResult = .failure(.keychainItemCorrupted)

        let sut = makeSUT(privateKeyRepository: repository)

        let firstError = await #expect(throws: DeviceKeyManagerError.self) {
            _ = try await sut.publicKey
        }

        guard case .privateKeyUnavailable(.keychainItemCorrupted) = firstError else {
            Issue.record("Expected .privateKeyUnavailable(.keychainItemCorrupted), got \(firstError)")
            return
        }

        #expect(repository.receivedMessages == [.privateKey])

        let expectedPrivateKey = try StubDevicePrivateKey(publicKeyResult: .success(.stub), signResult: .success(.stub))
        repository.privateKeyResult = .success(expectedPrivateKey)

        let recoveredPublicKey = try await sut.publicKey

        #expect(try recoveredPublicKey == expectedPrivateKey.publicKey)
        #expect(repository.receivedMessages == [.privateKey, .privateKey])
    }

    @Test
    func publicKeyAccessPropagatesPublicKeyConstructionFailure() async throws {
        let rawPointFormatError = DevicePublicKey.RawPointFormatError.invalidLength(actual: 0)
        let devicePrivateKey = try StubDevicePrivateKey(
            publicKeyResult: .failure(rawPointFormatError),
            signResult: .success(.stub)
        )

        let sut = makeSUT(privateKeyRepository: StubDevicePrivateKeyRepository(result: .success(devicePrivateKey)))

        let deviceKeyManagerError = await #expect(throws: DeviceKeyManagerError.self) {
            _ = try await sut.publicKey
        }

        guard case .publicKeyConstructionFailed(rawPointFormatError) = deviceKeyManagerError else {
            Issue.record("Expected .publicKeyConstructionFailed(\(rawPointFormatError), got \(deviceKeyManagerError)")
            return
        }
    }

    @Test
    func signPropagatesSigningFailure() async throws {
        let devicePrivateKey = try StubDevicePrivateKey(
            publicKeyResult: .success(.stub),
            signResult: .failure(SigningError.stub)
        )

        let sut = makeSUT(privateKeyRepository: StubDevicePrivateKeyRepository(result: .success(devicePrivateKey)))
        let anyData = Data()

        let deviceKeyManagerError = await #expect(throws: DeviceKeyManagerError.self) {
            _ = try await sut.sign(data: anyData)
        }

        guard case .signingFailed(underlying: SigningError.stub) = deviceKeyManagerError else {
            Issue.record("Expected .signingFailed(SigningError.stub), got \(deviceKeyManagerError)")
            return
        }
    }
}

// MARK: - Factory methods

extension DeviceKeyManagerTests {
    private func makeSUT(
        privateKeyRepository: some DevicePrivateKeyRepository = FakeDevicePrivateKeyRepository()
    ) -> DeviceKeyManager {
        trackForMemoryLeaks(DeviceKeyManager(privateKeyRepository: privateKeyRepository))
    }
}

private enum SigningError: Error {
    case stub
}
