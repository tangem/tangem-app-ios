//
//  NonceDecryptorTests.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Security
import Testing
@testable import TangemBackendAuthentication

@Suite(.tags(.backendAuthentication))
struct NonceDecryptorTests {
    @Test(arguments: Self.validKeyPairs)
    func decryptSucceedsForCorrectKeyPair(_ keyPair: KeyPair) throws {
        let sut = makeSUT(appPrivateKey: keyPair.privateKey)
        let expectedNoncePayload = Data("any nonce payload".utf8)
        let cipheredNonce = try Self.encrypt(expectedNoncePayload, with: keyPair.publicKey)

        let actualNoncePayload = try sut.decrypt(cipheredNonce: cipheredNonce)

        #expect(actualNoncePayload == expectedNoncePayload)
    }

    @Test
    func decryptPropagatesAppPrivateKeyParsingFailure() throws {
        let sut = NonceDecryptor(appPrivateKey: "any non-base64 string")
        let anyCipheredNonce = Data()

        let error = try #require(throws: NonceDecryptorError.self) {
            _ = try sut.decrypt(cipheredNonce: anyCipheredNonce)
        }

        guard case .appPrivateKeyParsingFailed = error else {
            Issue.record("Expected NonceDecryptorError.appPrivateKeyParsingFailed, got \(error)")
            return
        }
    }

    @Test(arguments: Self.mismatchedKeyPairs)
    func decryptThrowsDecryptFailureForMismatchedKeyPair(_ mismatchedKeyPair: KeyPair) throws {
        let sut = makeSUT(appPrivateKey: mismatchedKeyPair.privateKey)
        let mismatchedCipherText = try Self.encrypt(Data("mismatched key".utf8), with: mismatchedKeyPair.publicKey)

        let error = try #require(throws: NonceDecryptorError.self) {
            _ = try sut.decrypt(cipheredNonce: mismatchedCipherText)
        }

        guard case .decryptFailed = error else {
            Issue.record("Expected .decryptFailed, got \(error)")
            return
        }
    }

    @Test(arguments: Self.invalidCipheredNonces)
    func decryptThrowsDecryptFailureForInvalidCipheredNonce(invalidCipheredNonce: Data) throws {
        let sut = makeSUT(appPrivateKey: KeyPair.pkcs1.privateKey)

        let error = try #require(throws: NonceDecryptorError.self) {
            _ = try sut.decrypt(cipheredNonce: invalidCipheredNonce)
        }

        guard case .decryptFailed = error else {
            Issue.record("Expected .decryptFailed, got \(error)")
            return
        }
    }
}

// MARK: - Factory methods and testing utilities

extension NonceDecryptorTests {
    private static func encrypt(_ plaintext: Data, with publicKeyDer: String) throws -> Data {
        let publicKeyDERBytes = try #require(Data(base64Encoded: publicKeyDer))

        let attributes: [CFString: Any] = [
            kSecAttrKeyType: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass: kSecAttrKeyClassPublic,
        ]

        var keyCreationError: Unmanaged<CFError>?
        let publicKey = try #require(
            SecKeyCreateWithData(publicKeyDERBytes as CFData, attributes as CFDictionary, &keyCreationError)
        )

        var encryptionError: Unmanaged<CFError>?
        let cipherText = try #require(
            SecKeyCreateEncryptedData(publicKey, SecKeyAlgorithm.rsaEncryptionOAEPSHA256, plaintext as CFData, &encryptionError)
        )

        return cipherText as Data
    }

    private func makeSUT(appPrivateKey: String) -> NonceDecryptor {
        NonceDecryptor(appPrivateKey: appPrivateKey)
    }
}

extension NonceDecryptorTests {
    static let validKeyPairs = [
        KeyPair.pkcs1,
        KeyPair.pkcs8,
    ]

    static let mismatchedKeyPairs = [
        KeyPair.mismatchedPKCS1,
        KeyPair.mismatchedPKCS8,
    ]

    static let invalidCipheredNonces = [
        InvalidCipheredNonce.corruptedText,
        InvalidCipheredNonce.wrongLength,
    ]

    struct KeyPair {
        let privateKey: String
        let publicKey: String

        static let pkcs1 = KeyPair(privateKey: RSAKeyFixture.privateKeyPKCS1, publicKey: RSAKeyFixture.publicKey)
        static let pkcs8 = KeyPair(privateKey: RSAKeyFixture.privateKeyPKCS8, publicKey: RSAKeyFixture.publicKey)

        static let mismatchedPKCS1 = KeyPair(
            privateKey: RSAKeyFixture.privateKeyPKCS1,
            publicKey: RSAKeyFixture.anotherPublicKey
        )
        static let mismatchedPKCS8 = KeyPair(
            privateKey: RSAKeyFixture.privateKeyPKCS8,
            publicKey: RSAKeyFixture.anotherPublicKey
        )
    }

    private enum InvalidCipheredNonce {
        static let corruptedText = Data(repeating: 0xFF, count: 256)
        static let wrongLength = Data([0x00, 0x01, 0x02])
    }
}
