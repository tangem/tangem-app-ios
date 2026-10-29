//
//  DeviceCheckAppAttestServiceTests.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct CryptoKit.SHA256
import DeviceCheck
import Foundation
import os.lock
import Testing
import TangemLogger
@testable import TangemBackendAuthentication

@Suite(.tags(.backendAuthentication))
struct DeviceCheckAppAttestServiceTests {
    @Test
    func attestGeneratesKeyAttestsItAndPersistsKeyID() async throws {
        let appAttestService = SpyDCAppAttestService()
        let expectedKeyID = "some key id"
        let expectedAttestationObject = Data("some attestation object".utf8)
        appAttestService.generateKeyResult = Result.success(expectedKeyID)
        appAttestService.attestKeyResult = Result.success(expectedAttestationObject)

        let keyIDRepository = SpyKeychainRepository()
        keyIDRepository.insertResult = Result.success(())

        let analyticsReporter = SpyBackendAuthenticationAppAttestAnalyticsReporter()

        let sut = Self.makeSUT(
            appAttestService: appAttestService,
            keyIDRepository: keyIDRepository,
            analytics: analyticsReporter
        )

        let decryptedNonceBytes = Data("some decrypted nonce".utf8)
        let expectedClientDataHash = Self.makeClientDataHash(from: decryptedNonceBytes)

        let attestation = try await sut.attest(decryptedNonceBytes: decryptedNonceBytes)

        #expect(attestation == AppAttestation(keyID: expectedKeyID, object: expectedAttestationObject))
        #expect(appAttestService.receivedMessages == [.generateKey, .attestKey(expectedKeyID, expectedClientDataHash)])
        #expect(keyIDRepository.receivedMessages == [.insert(Data(expectedKeyID.utf8))])
        #expect(analyticsReporter.receivedMessages.isEmpty)
    }

    @Test
    func attestThrowsKeyGenerationFailedWhenKeyGenerationFails() async throws {
        let appAttestService = SpyDCAppAttestService()
        let expectedKeyGenerationError = AnyTestError()
        appAttestService.generateKeyResult = Result.failure(expectedKeyGenerationError)

        let keyIDRepository = SpyKeychainRepository()
        let analyticsReporter = SpyBackendAuthenticationAppAttestAnalyticsReporter()

        let sut = Self.makeSUT(
            appAttestService: appAttestService,
            keyIDRepository: keyIDRepository,
            analytics: analyticsReporter
        )

        let error = try await #require(throws: AppAttestServiceError.self) {
            _ = try await sut.attest(decryptedNonceBytes: Data("some decrypted nonce".utf8))
        }

        guard case .keyGenerationFailed(underlying: expectedKeyGenerationError) = error else {
            Issue.record("Expected .keyGenerationFailed, got \(error)")
            return
        }

        #expect(appAttestService.receivedMessages == [.generateKey])
        #expect(keyIDRepository.receivedMessages.isEmpty)

        #expect(analyticsReporter.receivedMessages.count == 1)
        guard
            case .reportAttestationFailed(.keyGenerationFailed(underlying: expectedKeyGenerationError))? =
            analyticsReporter.receivedMessages.first
        else {
            Issue.record("Expected .reportAttestationFailed(.keyGenerationFailed), got \(analyticsReporter.receivedMessages)")
            return
        }
    }

    @Test
    func attestThrowsAttestationServerUnavailableWhenAppleServerIsUnavailable() async throws {
        let appAttestService = SpyDCAppAttestService()
        let expectedKeyID = "some key id"
        appAttestService.generateKeyResult = Result.success(expectedKeyID)
        appAttestService.attestKeyResult = Result.failure(DCError(.serverUnavailable))

        let keyIDRepository = SpyKeychainRepository()
        let analyticsReporter = SpyBackendAuthenticationAppAttestAnalyticsReporter()

        let sut = Self.makeSUT(
            appAttestService: appAttestService,
            keyIDRepository: keyIDRepository,
            analytics: analyticsReporter
        )

        let decryptedNonceBytes = Data("some decrypted nonce".utf8)
        let expectedClientDataHash = Self.makeClientDataHash(from: decryptedNonceBytes)

        let error = try await #require(throws: AppAttestServiceError.self) {
            _ = try await sut.attest(decryptedNonceBytes: decryptedNonceBytes)
        }

        guard case .attestationServerUnavailable = error else {
            Issue.record("Expected .attestationServerUnavailable, got \(error)")
            return
        }

        #expect(appAttestService.receivedMessages == [.generateKey, .attestKey(expectedKeyID, expectedClientDataHash)])
        #expect(keyIDRepository.receivedMessages.isEmpty)

        #expect(analyticsReporter.receivedMessages.count == 1)
        guard case .reportAttestationFailed(.attestationServerUnavailable)? = analyticsReporter.receivedMessages.first else {
            Issue.record(
                "Expected .reportAttestationFailed(.attestationServerUnavailable), got \(analyticsReporter.receivedMessages)"
            )
            return
        }
    }

    @Test
    func attestThrowsAttestationFailedWhenAttestKeyFails() async throws {
        let appAttestService = SpyDCAppAttestService()
        let expectedKeyID = "some key id"
        let expectedAttestationError = AnyTestError()
        appAttestService.generateKeyResult = Result.success(expectedKeyID)
        appAttestService.attestKeyResult = Result.failure(expectedAttestationError)

        let keyIDRepository = SpyKeychainRepository()
        let analyticsReporter = SpyBackendAuthenticationAppAttestAnalyticsReporter()

        let sut = Self.makeSUT(
            appAttestService: appAttestService,
            keyIDRepository: keyIDRepository,
            analytics: analyticsReporter
        )

        let decryptedNonceBytes = Data("some decrypted nonce".utf8)
        let expectedClientDataHash = Self.makeClientDataHash(from: decryptedNonceBytes)

        let error = try await #require(throws: AppAttestServiceError.self) {
            _ = try await sut.attest(decryptedNonceBytes: decryptedNonceBytes)
        }

        guard case .attestationFailed(underlying: expectedAttestationError) = error else {
            Issue.record("Expected .attestationFailed, got \(error)")
            return
        }

        #expect(appAttestService.receivedMessages == [.generateKey, .attestKey(expectedKeyID, expectedClientDataHash)])
        #expect(keyIDRepository.receivedMessages.isEmpty)

        #expect(analyticsReporter.receivedMessages.count == 1)
        guard
            case .reportAttestationFailed(.attestationFailed(underlying: expectedAttestationError))? =
            analyticsReporter.receivedMessages.first
        else {
            Issue.record("Expected .reportAttestationFailed(.attestationFailed), got \(analyticsReporter.receivedMessages)")
            return
        }
    }

    @Test
    func attestThrowsKeychainFailureWhenKeyIDPersistenceFails() async throws {
        let appAttestService = SpyDCAppAttestService()
        let expectedKeyID = "some key id"
        appAttestService.generateKeyResult = Result.success(expectedKeyID)
        appAttestService.attestKeyResult = Result.success(Data("some attestation object".utf8))

        let keyIDRepository = SpyKeychainRepository()
        let expectedKeychainError = KeychainRepositoryError.insertFailed(status: errSecInteractionNotAllowed)
        keyIDRepository.insertResult = Result.failure(expectedKeychainError)

        let analyticsReporter = SpyBackendAuthenticationAppAttestAnalyticsReporter()

        let sut = Self.makeSUT(
            appAttestService: appAttestService,
            keyIDRepository: keyIDRepository,
            analytics: analyticsReporter
        )

        let decryptedNonceBytes = Data("some decrypted nonce".utf8)
        let expectedClientDataHash = Self.makeClientDataHash(from: decryptedNonceBytes)

        let error = try await #require(throws: AppAttestServiceError.self) {
            _ = try await sut.attest(decryptedNonceBytes: decryptedNonceBytes)
        }

        guard case .keychainFailure(expectedKeychainError) = error else {
            Issue.record("Expected .keychainFailure(\(expectedKeychainError)), got \(error)")
            return
        }

        #expect(appAttestService.receivedMessages == [.generateKey, .attestKey(expectedKeyID, expectedClientDataHash)])
        #expect(keyIDRepository.receivedMessages == [.insert(Data(expectedKeyID.utf8))])

        #expect(analyticsReporter.receivedMessages.count == 1)
        guard case .reportAttestationFailed(.keychainFailure(expectedKeychainError))? = analyticsReporter.receivedMessages.first else {
            Issue.record("Expected .reportAttestationFailed(.keychainFailure), got \(analyticsReporter.receivedMessages)")
            return
        }
    }

    @Test
    func assertRetrievesKeyIDAndGeneratesAssertion() async throws {
        let appAttestService = SpyDCAppAttestService()
        let expectedAssertionObject = Data("some assertion object".utf8)
        appAttestService.generateAssertionResult = Result.success(expectedAssertionObject)

        let keyIDRepository = SpyKeychainRepository()
        let expectedKeyID = "some key id"
        keyIDRepository.retrieveResult = Result.success(Data(expectedKeyID.utf8))

        let analyticsReporter = SpyBackendAuthenticationAppAttestAnalyticsReporter()

        let sut = Self.makeSUT(
            appAttestService: appAttestService,
            keyIDRepository: keyIDRepository,
            analytics: analyticsReporter
        )

        let decryptedNonceBytes = Data("some decrypted nonce".utf8)
        let expectedClientDataHash = Self.makeClientDataHash(from: decryptedNonceBytes)

        let assertion = try await sut.assert(decryptedNonceBytes: decryptedNonceBytes)

        #expect(assertion == AppAssertion(keyID: expectedKeyID, object: expectedAssertionObject))
        #expect(keyIDRepository.receivedMessages == [.retrieve])
        #expect(appAttestService.receivedMessages == [.generateAssertion(expectedKeyID, expectedClientDataHash)])
        #expect(analyticsReporter.receivedMessages.isEmpty)
    }

    @Test
    func assertThrowsAssertionKeyNotFoundWhenNoKeyIDIsStored() async throws {
        let appAttestService = SpyDCAppAttestService()

        let keyIDRepository = SpyKeychainRepository()
        keyIDRepository.retrieveResult = Result.success(nil)

        let analyticsReporter = SpyBackendAuthenticationAppAttestAnalyticsReporter()

        let sut = Self.makeSUT(
            appAttestService: appAttestService,
            keyIDRepository: keyIDRepository,
            analytics: analyticsReporter
        )

        let error = try await #require(throws: AppAttestServiceError.self) {
            _ = try await sut.assert(decryptedNonceBytes: Data("some decrypted nonce".utf8))
        }

        guard case .assertionKeyNotFound = error else {
            Issue.record("Expected .assertionKeyNotFound, got \(error)")
            return
        }

        #expect(keyIDRepository.receivedMessages == [.retrieve])
        #expect(appAttestService.receivedMessages.isEmpty)

        #expect(analyticsReporter.receivedMessages.count == 1)
        guard case .reportAssertionFailed(.assertionKeyNotFound)? = analyticsReporter.receivedMessages.first else {
            Issue.record("Expected .reportAssertionFailed(.assertionKeyNotFound), got \(analyticsReporter.receivedMessages)")
            return
        }
    }

    @Test
    func assertDeletesKeyIDAndThrowsAssertionKeyCorruptedWhenStoredKeyIDIsMalformed() async throws {
        let appAttestService = SpyDCAppAttestService()

        let keyIDRepository = SpyKeychainRepository()
        keyIDRepository.retrieveResult = Result.success(Data([0xFF]))
        keyIDRepository.deleteResult = Result.success(())

        let analyticsReporter = SpyBackendAuthenticationAppAttestAnalyticsReporter()

        let sut = Self.makeSUT(
            appAttestService: appAttestService,
            keyIDRepository: keyIDRepository,
            analytics: analyticsReporter
        )

        let error = try await #require(throws: AppAttestServiceError.self) {
            _ = try await sut.assert(decryptedNonceBytes: Data("some decrypted nonce".utf8))
        }

        guard case .assertionKeyCorrupted = error else {
            Issue.record("Expected .assertionKeyCorrupted, got \(error)")
            return
        }

        #expect(keyIDRepository.receivedMessages == [.retrieve, .delete])
        #expect(appAttestService.receivedMessages.isEmpty)

        #expect(analyticsReporter.receivedMessages.count == 1)
        guard case .reportAssertionFailed(.assertionKeyCorrupted)? = analyticsReporter.receivedMessages.first else {
            Issue.record("Expected .reportAssertionFailed(.assertionKeyCorrupted), got \(analyticsReporter.receivedMessages)")
            return
        }
    }

    @Test
    func assertThrowsKeychainFailureWhenKeyIDRetrievalFails() async throws {
        let appAttestService = SpyDCAppAttestService()

        let keyIDRepository = SpyKeychainRepository()
        let expectedKeychainError = KeychainRepositoryError.retrieveFailed(status: errSecInteractionNotAllowed)
        keyIDRepository.retrieveResult = Result.failure(expectedKeychainError)

        let analyticsReporter = SpyBackendAuthenticationAppAttestAnalyticsReporter()

        let sut = Self.makeSUT(
            appAttestService: appAttestService,
            keyIDRepository: keyIDRepository,
            analytics: analyticsReporter
        )

        let error = try await #require(throws: AppAttestServiceError.self) {
            _ = try await sut.assert(decryptedNonceBytes: Data("some decrypted nonce".utf8))
        }

        guard case .keychainFailure(expectedKeychainError) = error else {
            Issue.record("Expected .keychainFailure(\(expectedKeychainError)), got \(error)")
            return
        }

        #expect(keyIDRepository.receivedMessages == [.retrieve])
        #expect(appAttestService.receivedMessages.isEmpty)

        #expect(analyticsReporter.receivedMessages.count == 1)
        guard case .reportAssertionFailed(.keychainFailure(expectedKeychainError))? = analyticsReporter.receivedMessages.first else {
            Issue.record("Expected .reportAssertionFailed(.keychainFailure), got \(analyticsReporter.receivedMessages)")
            return
        }
    }

    @Test
    func assertDeletesKeyIDAndThrowsAssertionKeyCorruptedWhenKeyIsInvalid() async throws {
        let appAttestService = SpyDCAppAttestService()
        appAttestService.generateAssertionResult = Result.failure(DCError(.invalidKey))

        let keyIDRepository = SpyKeychainRepository()
        let expectedKeyID = "some key id"
        keyIDRepository.retrieveResult = Result.success(Data(expectedKeyID.utf8))
        keyIDRepository.deleteResult = Result.success(())

        let analyticsReporter = SpyBackendAuthenticationAppAttestAnalyticsReporter()

        let sut = Self.makeSUT(
            appAttestService: appAttestService,
            keyIDRepository: keyIDRepository,
            analytics: analyticsReporter
        )

        let decryptedNonceBytes = Data("some decrypted nonce".utf8)
        let expectedClientDataHash = Self.makeClientDataHash(from: decryptedNonceBytes)

        let error = try await #require(throws: AppAttestServiceError.self) {
            _ = try await sut.assert(decryptedNonceBytes: decryptedNonceBytes)
        }

        guard case .assertionKeyCorrupted = error else {
            Issue.record("Expected .assertionKeyCorrupted, got \(error)")
            return
        }

        #expect(keyIDRepository.receivedMessages == [.retrieve, .delete])
        #expect(appAttestService.receivedMessages == [.generateAssertion(expectedKeyID, expectedClientDataHash)])

        #expect(analyticsReporter.receivedMessages.count == 1)
        guard case .reportAssertionFailed(.assertionKeyCorrupted)? = analyticsReporter.receivedMessages.first else {
            Issue.record("Expected .reportAssertionFailed(.assertionKeyCorrupted), got \(analyticsReporter.receivedMessages)")
            return
        }
    }

    @Test
    func assertThrowsAssertionKeyCorruptedEvenWhenKeyIDDeletionFails() async throws {
        let appAttestService = SpyDCAppAttestService()
        appAttestService.generateAssertionResult = Result.failure(DCError(.invalidKey))

        let keyIDRepository = SpyKeychainRepository()
        let expectedKeyID = "some key id"
        keyIDRepository.retrieveResult = Result.success(Data(expectedKeyID.utf8))
        keyIDRepository.deleteResult = Result.failure(.deleteFailed(status: errSecInteractionNotAllowed))

        let analyticsReporter = SpyBackendAuthenticationAppAttestAnalyticsReporter()

        let sut = Self.makeSUT(
            appAttestService: appAttestService,
            keyIDRepository: keyIDRepository,
            analytics: analyticsReporter
        )

        let decryptedNonceBytes = Data("some decrypted nonce".utf8)
        let expectedClientDataHash = Self.makeClientDataHash(from: decryptedNonceBytes)

        let error = try await #require(throws: AppAttestServiceError.self) {
            _ = try await sut.assert(decryptedNonceBytes: decryptedNonceBytes)
        }

        guard case .assertionKeyCorrupted = error else {
            Issue.record("Expected .assertionKeyCorrupted, got \(error)")
            return
        }

        #expect(keyIDRepository.receivedMessages == [.retrieve, .delete])
        #expect(appAttestService.receivedMessages == [.generateAssertion(expectedKeyID, expectedClientDataHash)])

        #expect(analyticsReporter.receivedMessages.count == 1)
        guard case .reportAssertionFailed(.assertionKeyCorrupted)? = analyticsReporter.receivedMessages.first else {
            Issue.record("Expected .reportAssertionFailed(.assertionKeyCorrupted), got \(analyticsReporter.receivedMessages)")
            return
        }
    }

    @Test
    func assertThrowsAssertionFailedWhenGenerateAssertionFails() async throws {
        let appAttestService = SpyDCAppAttestService()
        let expectedAssertionError = AnyTestError()
        appAttestService.generateAssertionResult = Result.failure(expectedAssertionError)

        let keyIDRepository = SpyKeychainRepository()
        let expectedKeyID = "some key id"
        keyIDRepository.retrieveResult = Result.success(Data(expectedKeyID.utf8))

        let analyticsReporter = SpyBackendAuthenticationAppAttestAnalyticsReporter()

        let sut = Self.makeSUT(
            appAttestService: appAttestService,
            keyIDRepository: keyIDRepository,
            analytics: analyticsReporter
        )

        let decryptedNonceBytes = Data("some decrypted nonce".utf8)
        let expectedClientDataHash = Self.makeClientDataHash(from: decryptedNonceBytes)

        let error = try await #require(throws: AppAttestServiceError.self) {
            _ = try await sut.assert(decryptedNonceBytes: decryptedNonceBytes)
        }

        guard case .assertionFailed(underlying: expectedAssertionError) = error else {
            Issue.record("Expected .assertionFailed, got \(error)")
            return
        }

        #expect(keyIDRepository.receivedMessages == [.retrieve])
        #expect(appAttestService.receivedMessages == [.generateAssertion(expectedKeyID, expectedClientDataHash)])

        #expect(analyticsReporter.receivedMessages.count == 1)
        guard
            case .reportAssertionFailed(.assertionFailed(underlying: expectedAssertionError))? =
            analyticsReporter.receivedMessages.first
        else {
            Issue.record("Expected .reportAssertionFailed(.assertionFailed), got \(analyticsReporter.receivedMessages)")
            return
        }
    }
}

extension DeviceCheckAppAttestServiceTests {
    private static func makeSUT(
        appAttestService: DCAppAttestService,
        keyIDRepository: some KeychainRepository,
        analytics: some BackendAuthenticationAppAttestAnalyticsReporter
    ) -> some AppAttestService {
        DeviceCheckAppAttestService(
            appAttestService: appAttestService,
            keyIDRepository: keyIDRepository,
            analyticsReporter: analytics,
            logger: TangemLogger.Logger(category: OSLogCategory(name: "Tests"))
        )
    }

    private static func makeClientDataHash(from decryptedNonceBytes: Data) -> Data {
        let formattedNonceHashString = Data(SHA256.hash(data: decryptedNonceBytes)).base64EncodedString()
        return Data(SHA256.hash(data: Data(formattedNonceHashString.utf8)))
    }
}

private final class SpyDCAppAttestService: DCAppAttestService, @unchecked Sendable {
    private let state = OSAllocatedUnfairLock(initialState: State())

    var generateKeyResult: Result<String, any Error> {
        get { state.withLock(\.generateKeyResult) }
        set { state.withLock { $0.generateKeyResult = newValue } }
    }

    var attestKeyResult: Result<Data, any Error> {
        get { state.withLock(\.attestKeyResult) }
        set { state.withLock { $0.attestKeyResult = newValue } }
    }

    var generateAssertionResult: Result<Data, any Error> {
        get { state.withLock(\.generateAssertionResult) }
        set { state.withLock { $0.generateAssertionResult = newValue } }
    }

    var receivedMessages: [Message] {
        state.withLock(\.receivedMessages)
    }

    override var isSupported: Bool {
        true
    }

    override func generateKey() async throws -> String {
        state.withLock { $0.receivedMessages.append(.generateKey) }
        return try generateKeyResult.get()
    }

    override func attestKey(_ keyID: String, clientDataHash: Data) async throws -> Data {
        state.withLock { $0.receivedMessages.append(.attestKey(keyID, clientDataHash)) }
        return try attestKeyResult.get()
    }

    override func generateAssertion(_ keyID: String, clientDataHash: Data) async throws -> Data {
        state.withLock { $0.receivedMessages.append(.generateAssertion(keyID, clientDataHash)) }
        return try generateAssertionResult.get()
    }
}

extension SpyDCAppAttestService {
    enum Message: Equatable {
        case generateKey
        case attestKey(String, Data)
        case generateAssertion(String, Data)
    }

    private struct State {
        var generateKeyResult = Result<String, any Error>.failure(AnyTestError())
        var attestKeyResult = Result<Data, any Error>.failure(AnyTestError())
        var generateAssertionResult = Result<Data, any Error>.failure(AnyTestError())
        var receivedMessages = [Message]()
    }
}
