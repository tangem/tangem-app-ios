//
//  SessionAuthenticationRequestMapper.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

private import struct Foundation.Data

enum SessionAuthenticationRequestMapper {
    static func map(fromDomain request: SessionAuthenticationRequest) -> AuthenticateDTO.Request {
        AuthenticateDTO.Request(
            payload: AuthenticateDTO.Request.Payload(
                devicePublicKey: request.devicePublicKey.derRepresentation.base64EncodedString(),
                nonce: request.decryptedNonce,
                attestationToken: request.appAttestToken?.object.base64EncodedString(),
                appAttestKeyId: request.appAttestToken?.keyID,
                metadata: DeviceMetadataMapper.mapToDTO(request.metadata)
            ),
            signature: request.signature.derRepresentation.base64EncodedString()
        )
    }
}
