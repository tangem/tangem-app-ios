//
//  HPKEEnvelope.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import CryptoKit
import Testing
import Foundation

@available(iOS 17.0, *)
struct HPKEEnvelope {
    static let backendInfo = Data("tangem/social-recovery/v1".utf8)

    let encBase64: String
    let ciphertextBase64: String

    static func seal(
        _ plaintext: Data,
        recipientPublicKeyBase64: String,
        info: Data = backendInfo
    ) throws -> HPKEEnvelope {
        let rawPublicKey = try #require(Data(base64Encoded: recipientPublicKeyBase64))
        let recipientKey = try Curve25519.KeyAgreement.PublicKey(rawRepresentation: rawPublicKey)

        var sender = try HPKE.Sender(
            recipientKey: recipientKey,
            ciphersuite: HPKE.Ciphersuite(kem: .Curve25519_HKDF_SHA256, kdf: .HKDF_SHA256, aead: .AES_GCM_256),
            info: info
        )
        let ciphertext = try sender.seal(plaintext)

        return HPKEEnvelope(
            encBase64: sender.encapsulatedKey.base64EncodedString(),
            ciphertextBase64: ciphertext.base64EncodedString()
        )
    }
}
