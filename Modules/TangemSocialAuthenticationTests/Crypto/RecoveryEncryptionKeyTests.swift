//
//  RecoveryEncryptionKeyTests.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import CryptoKit
import Foundation
import Testing
@testable import TangemSocialAuthentication

@Suite("RecoveryEncryptionKey", .tags(.socialAuthentication))
struct RecoveryEncryptionKeyTests {
    @Test("Public key is the base64 of a raw X25519 public key")
    func publicKeyIsBase64OfARawX25519PublicKey() throws {
        let key = RecoveryEncryptionKey()

        let rawPublicKey = try #require(Data(base64Encoded: key.publicKeyBase64))

        #expect(throws: Never.self) {
            try Curve25519.KeyAgreement.PublicKey(rawRepresentation: rawPublicKey)
        }
    }

    @Test("Every key is generated fresh")
    func everyKeyIsFresh() {
        #expect(RecoveryEncryptionKey().publicKeyBase64 != RecoveryEncryptionKey().publicKeyBase64)
    }

    @available(iOS 17.0, *)
    @Test("An envelope sealed to the public key decrypts to the plaintext")
    func decryptOpensAnEnvelopeSealedToThePublicKey() throws {
        let key = RecoveryEncryptionKey()
        let recoveryKey = Data((0 ..< 32).map(UInt8.init))
        let envelope = try HPKEEnvelope.seal(recoveryKey, recipientPublicKeyBase64: key.publicKeyBase64)

        let decrypted = try key.decrypt(encBase64: envelope.encBase64, ciphertextBase64: envelope.ciphertextBase64)

        #expect(decrypted == recoveryKey)
    }

    @available(iOS 17.0, *)
    @Test("A wallet binding decrypts its own envelope with the key it holds")
    func walletBindingDecryptsItsOwnEnvelope() throws {
        let key = RecoveryEncryptionKey()
        let recoveryKey = Data("raw-recovery-key".utf8)
        let envelope = try HPKEEnvelope.seal(recoveryKey, recipientPublicKeyBase64: key.publicKeyBase64)
        let binding = SocialAuthWalletBinding(
            enc: envelope.encBase64,
            ct: envelope.ciphertextBase64,
            recoveryEncryptionKey: key
        )

        #expect(try binding.decryptRecoveryKey() == recoveryKey)
    }

    @available(iOS 17.0, *)
    @Test("An encapsulated key that is not base64 is an invalid envelope")
    func decryptRejectsAnEncapsulatedKeyThatIsNotBase64() throws {
        let key = RecoveryEncryptionKey()
        let envelope = try HPKEEnvelope.seal(Data([0x01]), recipientPublicKeyBase64: key.publicKeyBase64)

        let error = try #require(throws: RecoveryEncryptionKey.DecryptionError.self) {
            try key.decrypt(encBase64: "not base64!", ciphertextBase64: envelope.ciphertextBase64)
        }

        #expect(error == .invalidEnvelope)
    }

    @available(iOS 17.0, *)
    @Test("An encapsulated key of the wrong size is an invalid envelope", arguments: [Sizes.encapsulatedKey - 1, Sizes.encapsulatedKey + 1])
    func decryptRejectsAnEncapsulatedKeyOfWrongSize(size: Int) throws {
        let key = RecoveryEncryptionKey()
        let envelope = try HPKEEnvelope.seal(Data([0x01]), recipientPublicKeyBase64: key.publicKeyBase64)
        let wrongSizedEnc = Data(repeating: 0xAB, count: size).base64EncodedString()

        let error = try #require(throws: RecoveryEncryptionKey.DecryptionError.self) {
            try key.decrypt(encBase64: wrongSizedEnc, ciphertextBase64: envelope.ciphertextBase64)
        }

        #expect(error == .invalidEnvelope)
    }

    @available(iOS 17.0, *)
    @Test("A ciphertext that is not base64 is an invalid envelope")
    func decryptRejectsACiphertextThatIsNotBase64() throws {
        let key = RecoveryEncryptionKey()
        let envelope = try HPKEEnvelope.seal(Data([0x01]), recipientPublicKeyBase64: key.publicKeyBase64)

        let error = try #require(throws: RecoveryEncryptionKey.DecryptionError.self) {
            try key.decrypt(encBase64: envelope.encBase64, ciphertextBase64: "not base64!")
        }

        #expect(error == .invalidEnvelope)
    }

    @available(iOS 17.0, *)
    @Test("A ciphertext no longer than the GCM tag is an invalid envelope", arguments: [0, Sizes.tag - 1, Sizes.tag])
    func decryptRejectsACiphertextNoLongerThanTheTag(size: Int) throws {
        let key = RecoveryEncryptionKey()
        let envelope = try HPKEEnvelope.seal(Data([0x01]), recipientPublicKeyBase64: key.publicKeyBase64)
        let shortCiphertext = Data(repeating: 0xCD, count: size).base64EncodedString()

        let error = try #require(throws: RecoveryEncryptionKey.DecryptionError.self) {
            try key.decrypt(encBase64: envelope.encBase64, ciphertextBase64: shortCiphertext)
        }

        #expect(error == .invalidEnvelope)
    }

    @available(iOS 17.0, *)
    @Test("A tampered ciphertext fails to decrypt")
    func decryptFailsOnATamperedCiphertext() throws {
        let key = RecoveryEncryptionKey()
        let envelope = try HPKEEnvelope.seal(Data("payload".utf8), recipientPublicKeyBase64: key.publicKeyBase64)
        var ciphertext = try #require(Data(base64Encoded: envelope.ciphertextBase64))
        ciphertext[0] ^= 0xFF

        let error = try #require(throws: RecoveryEncryptionKey.DecryptionError.self) {
            try key.decrypt(encBase64: envelope.encBase64, ciphertextBase64: ciphertext.base64EncodedString())
        }

        #expect(error == .decryptionFailed)
    }

    @available(iOS 17.0, *)
    @Test("An envelope sealed to another key fails to decrypt")
    func decryptFailsOnAnEnvelopeSealedToAnotherKey() throws {
        let key = RecoveryEncryptionKey()
        let otherKey = RecoveryEncryptionKey()
        let envelope = try HPKEEnvelope.seal(Data("payload".utf8), recipientPublicKeyBase64: otherKey.publicKeyBase64)

        let error = try #require(throws: RecoveryEncryptionKey.DecryptionError.self) {
            try key.decrypt(encBase64: envelope.encBase64, ciphertextBase64: envelope.ciphertextBase64)
        }

        #expect(error == .decryptionFailed)
    }

    @available(iOS 17.0, *)
    @Test("An envelope sealed with another HPKE info string fails to decrypt")
    func decryptFailsOnAnEnvelopeSealedWithAnotherInfoString() throws {
        let key = RecoveryEncryptionKey()
        let envelope = try HPKEEnvelope.seal(
            Data("payload".utf8),
            recipientPublicKeyBase64: key.publicKeyBase64,
            info: Data("tangem/social-recovery/v2".utf8)
        )

        let error = try #require(throws: RecoveryEncryptionKey.DecryptionError.self) {
            try key.decrypt(encBase64: envelope.encBase64, ciphertextBase64: envelope.ciphertextBase64)
        }

        #expect(error == .decryptionFailed)
    }
}

// MARK: - Sizes

private extension RecoveryEncryptionKeyTests {
    enum Sizes {
        static let encapsulatedKey = Curve25519.KeyAgreement.PrivateKey().publicKey.rawRepresentation.count
        static let tag = try! AES.GCM.seal(Data(), using: SymmetricKey(size: .bits256)).tag.count
    }
}
