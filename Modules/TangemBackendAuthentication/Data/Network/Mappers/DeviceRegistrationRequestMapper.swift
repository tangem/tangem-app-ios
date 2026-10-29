//
//  DeviceRegistrationRequestMapper.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

private import struct Foundation.Data

enum DeviceRegistrationRequestMapper {
    static func map(fromDomain request: DeviceRegistrationRequest) -> RegisterDeviceDTO.Request {
        RegisterDeviceDTO.Request(
            payload: RegisterDeviceDTO.Request.Payload(
                devicePublicKey: request.devicePublicKey.derRepresentation.base64EncodedString(),
                nonce: request.decryptedNonce,
                attestationToken: request.appAttestation?.object.base64EncodedString(),
                appAttestKeyId: request.appAttestation?.keyID,
                metadata: DeviceMetadataMapper.mapToDTO(request.metadata)
            ),
            signature: request.signature.derRepresentation.base64EncodedString()
        )
    }
}
