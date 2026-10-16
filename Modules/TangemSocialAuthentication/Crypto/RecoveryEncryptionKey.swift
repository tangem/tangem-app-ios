//
//  RecoveryEncryptionKey.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import CryptoKit

/// Ephemeral X25519 key pair.
struct RecoveryEncryptionKey: Sendable {
    private let privateKey: Curve25519.KeyAgreement.PrivateKey

    init() {
        privateKey = Curve25519.KeyAgreement.PrivateKey()
    }

    /// Base64 of the raw 32-byte.
    var publicKeyBase64: String {
        privateKey.publicKey.rawRepresentation.base64EncodedString()
    }

    /// Opens the RFC 9180 HPKE envelope the backend sealed for this key:
    /// base mode, DHKEM(X25519, HKDF-SHA256), HKDF-SHA256, AES-256-GCM.
    ///
    /// - Parameters:
    ///   - encBase64: Base64 of the 32-byte encapsulated X25519 public key.
    ///   - ciphertextBase64: Base64 of the ciphertext followed by the 16-byte AES-GCM tag.
    func decrypt(encBase64: String, ciphertextBase64: String) throws(DecryptionError) -> Data {
        guard #available(iOS 17.0, *) else {
            throw .unsupportedOSVersion
        }

        guard
            let encapsulatedKey = Data(base64Encoded: encBase64),
            encapsulatedKey.count == Constants.encapsulatedKeySize,
            let ciphertext = Data(base64Encoded: ciphertextBase64),
            ciphertext.count > Constants.tagSize
        else {
            throw .invalidEnvelope
        }

        do {
            var recipient = try HPKE.Recipient(
                privateKey: privateKey,
                ciphersuite: HPKE.Ciphersuite(
                    kem: .Curve25519_HKDF_SHA256,
                    kdf: .HKDF_SHA256, aead: .AES_GCM_256
                ),
                info: Constants.info,
                encapsulatedKey: encapsulatedKey
            )
            return try recipient.open(ciphertext)
        } catch {
            throw .decryptionFailed
        }
    }
}

extension RecoveryEncryptionKey {
    enum DecryptionError: Error {
        case unsupportedOSVersion
        case invalidEnvelope
        case decryptionFailed
    }

    private enum Constants {
        /// Must match the backend's HPKE info string.
        static let info = Data("tangem/social-recovery/v1".utf8)
        static let encapsulatedKeySize = 32
        static let tagSize = 16
    }
}
