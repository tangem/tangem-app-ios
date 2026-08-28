//
//  NonceDTO.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

/// - `POST api/authentication/v1/mobile/nonce/device`
/// - `POST api/authentication/v1/mobile/nonce/auth`
/// - `POST api/authentication/v1/mobile/nonce/wallet`
enum NonceDTO {
    struct Request: Encodable {
        let devicePublicKey: String
    }

    struct Response: Decodable {
        let cipheredNonce: String
    }
}
