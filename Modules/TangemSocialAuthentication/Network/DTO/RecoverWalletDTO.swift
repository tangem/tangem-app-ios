//
//  RecoverWalletDTO.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

/// `POST api/authentication/v1/mobile/wallet/recover`
enum RecoverWalletDTO {
    struct Request: Encodable {
        let nonce: String
        let recoveryEncryptionPublicKey: String
        let deviceSignature: String
        let attestationToken: String?
        let appAttestKeyId: String?
        let providerIdToken: String
        let metadata: DeviceMetadataDTO
    }

    struct Response: Decodable {
        /// Base64 32-byte HPKE encapsulated X25519 public key.
        let enc: String

        /// Base64 HPKE ciphertext including the 16-byte AES-GCM tag.
        let ct: String
    }
}
