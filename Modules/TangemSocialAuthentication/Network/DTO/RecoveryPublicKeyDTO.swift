//
//  RecoveryPublicKeyDTO.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

/// `GET api/authentication/v1/mobile/wallet/recovery-public-key`
enum RecoveryPublicKeyDTO {
    /// RSA public key (JWK, RSA-OAEP-256).
    struct Response: Decodable {
        /// Key type, always `RSA`.
        let kty: String

        /// Key usage, always `enc`.
        let use: String

        /// Algorithm, always `RSA-OAEP-256`.
        let alg: String

        /// KMS recovery key identifier.
        let kid: String

        /// Base64url-encoded RSA modulus.
        let n: String

        /// Base64url-encoded RSA public exponent.
        let e: String
    }
}
