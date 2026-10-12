//
//  RegisterDeviceDTO.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

/// `POST api/authentication/v1/mobile/register`
enum RegisterDeviceDTO {
    struct Request: Encodable {
        let payload: Payload
        let signature: String
    }
}

extension RegisterDeviceDTO.Request {
    struct Payload: Encodable {
        let devicePublicKey: String
        let nonce: String
        let attestationToken: String?
        let metadata: DeviceMetadataDTO.Request
    }
}
