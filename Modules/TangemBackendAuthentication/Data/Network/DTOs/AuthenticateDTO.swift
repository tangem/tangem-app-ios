//
//  AuthenticateDTO.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

/// `POST api/authentication/v1/mobile/authenticate`
enum AuthenticateDTO {
    struct Request: Encodable {
        let payload: Payload
        let signature: String
    }
}

extension AuthenticateDTO.Request {
    struct Payload: Encodable {
        let devicePublicKey: String
        let nonce: String
        let attestationToken: String?
        let metadata: DeviceMetadataDTO.Request
    }
}
