//
//  SessionAuthenticationRequest+fake.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import CryptoKit
import Foundation
@testable import TangemBackendAuthentication

extension SessionAuthenticationRequest {
    static var fake: SessionAuthenticationRequest {
        get throws {
            SessionAuthenticationRequest(
                devicePublicKey: try DevicePublicKey.fake,
                decryptedNonce: "decrypted-nonce",
                metadata: DeviceMetadata.fake,
                signature: try DeviceSignature.fake,
                appAttestToken: nil
            )
        }
    }

    static func fake(
        devicePrivateKey: SpyDevicePrivateKey,
        decryptedNonce: String,
        appAttestToken: AppAttestToken?
    ) throws -> SessionAuthenticationRequest {
        let ecdsaSignature = try devicePrivateKey.signResult.get()

        return SessionAuthenticationRequest(
            devicePublicKey: try devicePrivateKey.publicKeyResult.get(),
            decryptedNonce: decryptedNonce,
            metadata: DeviceMetadata.fake,
            signature: try DeviceSignature(
                derRepresentation: ecdsaSignature.derRepresentation,
                rawRepresentation: ecdsaSignature.rawRepresentation
            ),
            appAttestToken: appAttestToken
        )
    }

    static func uniqueFake() throws -> SessionAuthenticationRequest {
        let appAttestation = AppAttestation(
            keyID: "key-id-\(UUID().uuidString)",
            object: Data("attestation-object-\(UUID().uuidString)".utf8)
        )

        return SessionAuthenticationRequest(
            devicePublicKey: try SpyDevicePrivateKey.successStub.publicKeyResult.get(),
            decryptedNonce: "decrypted-nonce-\(UUID().uuidString)",
            metadata: DeviceMetadata.fake,
            signature: try DeviceSignature.fake,
            appAttestToken: AppAttestToken(attestation: appAttestation)
        )
    }
}
