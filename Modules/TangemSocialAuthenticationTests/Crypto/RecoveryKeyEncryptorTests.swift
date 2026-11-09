//
//  RecoveryKeyEncryptorTests.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemFoundation
@testable import TangemSocialAuthentication

@Suite("RecoveryKeyEncryptor", .tags(.socialAuthentication))
struct RecoveryKeyEncryptorTests {
    private let recoveryKey = Data((0 ..< 32).map { UInt8($0 &* 7) })

    @Test("Encrypted key decrypts with the matching RSA private key")
    func encryptedKeyDecryptsWithTheMatchingPrivateKey() throws {
        let encrypted = try RecoveryKeyEncryptor().encrypt(recoveryKey: recoveryKey, publicKey: RSAKeyPairFixture.publicKeyJWK())

        #expect(try RSAKeyPairFixture.decrypt(base64Ciphertext: encrypted) == recoveryKey)
    }

    @Test("Ciphertext is the base64 of exactly one RSA block")
    func ciphertextIsBase64OfOneRSABlock() throws {
        let encrypted = try RecoveryKeyEncryptor().encrypt(recoveryKey: recoveryKey, publicKey: RSAKeyPairFixture.publicKeyJWK())

        let ciphertext = try #require(Data(base64Encoded: encrypted))

        #expect(ciphertext.count == RSAKeyPairFixture.keySizeInBits / 8)
    }

    @Test("OAEP padding makes two encryptions of the same key differ")
    func oaepPaddingIsRandomizedBetweenCalls() throws {
        let encryptor = RecoveryKeyEncryptor()

        let first = try encryptor.encrypt(recoveryKey: recoveryKey, publicKey: RSAKeyPairFixture.publicKeyJWK())
        let second = try encryptor.encrypt(recoveryKey: recoveryKey, publicKey: RSAKeyPairFixture.publicKeyJWK())

        #expect(first != second)
    }

    @Test("A modulus with a leading zero byte still yields a working key")
    func modulusWithALeadingZeroByteStillProducesAValidKey() throws {
        let paddedModulus = Data([0x00]) + RSAKeyPairFixture.modulus
        let publicKey = RSAKeyPairFixture.publicKeyJWK(n: paddedModulus.base64URLEncodedString)

        let encrypted = try RecoveryKeyEncryptor().encrypt(recoveryKey: recoveryKey, publicKey: publicKey)

        #expect(try RSAKeyPairFixture.decrypt(base64Ciphertext: encrypted) == recoveryKey)
    }

    @Test("The largest plaintext OAEP-SHA256 allows still encrypts")
    func largestOAEPPlaintextStillEncrypts() throws {
        let plaintext = Data(repeating: 0x5A, count: RSAKeyPairFixture.maximumOAEPSHA256PlaintextSize)

        let encrypted = try RecoveryKeyEncryptor().encrypt(recoveryKey: plaintext, publicKey: RSAKeyPairFixture.publicKeyJWK())

        #expect(try RSAKeyPairFixture.decrypt(base64Ciphertext: encrypted) == plaintext)
    }

    @Test("Any JWK algorithm but RSA-OAEP-256 is rejected and reported", arguments: ["RSA-OAEP", "RSA-OAEP-512", "RS256", ""])
    func encryptRejectsAnyAlgorithmButRSAOAEP256(algorithm: String) throws {
        let publicKey = RSAKeyPairFixture.publicKeyJWK(alg: algorithm)

        let error = try #require(throws: RecoveryKeyEncryptionError.self) {
            try RecoveryKeyEncryptor().encrypt(recoveryKey: recoveryKey, publicKey: publicKey)
        }

        guard case .unsupportedAlgorithm(let reported) = error else {
            Issue.record("Expected .unsupportedAlgorithm, got \(error)")
            return
        }

        #expect(reported == algorithm)
    }

    @Test("A modulus that is not base64url is an invalid public key")
    func encryptRejectsAModulusThatIsNotBase64URL() throws {
        let publicKey = RSAKeyPairFixture.publicKeyJWK(n: "not base64url!")

        let error = try #require(throws: RecoveryKeyEncryptionError.self) {
            try RecoveryKeyEncryptor().encrypt(recoveryKey: recoveryKey, publicKey: publicKey)
        }

        guard case .invalidPublicKey = error else {
            Issue.record("Expected .invalidPublicKey, got \(error)")
            return
        }
    }

    @Test("An exponent that is not base64url is an invalid public key")
    func encryptRejectsAnExponentThatIsNotBase64URL() throws {
        let publicKey = RSAKeyPairFixture.publicKeyJWK(e: "not base64url!")

        let error = try #require(throws: RecoveryKeyEncryptionError.self) {
            try RecoveryKeyEncryptor().encrypt(recoveryKey: recoveryKey, publicKey: publicKey)
        }

        guard case .invalidPublicKey = error else {
            Issue.record("Expected .invalidPublicKey, got \(error)")
            return
        }
    }

    @Test("A modulus that does not form an RSA key is an invalid public key")
    func encryptRejectsAModulusThatIsNotAnRSAKey() throws {
        let publicKey = RSAKeyPairFixture.publicKeyJWK(n: Data([0x01, 0x02, 0x03]).base64URLEncodedString)

        let error = try #require(throws: RecoveryKeyEncryptionError.self) {
            try RecoveryKeyEncryptor().encrypt(recoveryKey: recoveryKey, publicKey: publicKey)
        }

        guard case .invalidPublicKey = error else {
            Issue.record("Expected .invalidPublicKey, got \(error)")
            return
        }
    }

    @Test("A plaintext over the OAEP limit fails to encrypt")
    func encryptFailsWhenThePlaintextExceedsTheOAEPLimit() throws {
        let plaintext = Data(repeating: 0x5A, count: RSAKeyPairFixture.maximumOAEPSHA256PlaintextSize + 1)

        let error = try #require(throws: RecoveryKeyEncryptionError.self) {
            try RecoveryKeyEncryptor().encrypt(recoveryKey: plaintext, publicKey: RSAKeyPairFixture.publicKeyJWK())
        }

        guard case .encryptionFailed = error else {
            Issue.record("Expected .encryptionFailed, got \(error)")
            return
        }
    }
}
