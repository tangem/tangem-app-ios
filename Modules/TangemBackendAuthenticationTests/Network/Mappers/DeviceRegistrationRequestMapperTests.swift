//
//  DeviceRegistrationRequestMapperTests.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import TangemBackendAuthentication

@Suite(.tags(.backendAuthentication))
struct DeviceRegistrationRequestMapperTests {
    @Test(arguments: [AppAttestation.fake, nil])
    func mapFromDomainProducesCorrectRegisterDeviceDTORequest(appAttestation: AppAttestation?) throws {
        let request = DeviceRegistrationRequest(
            devicePublicKey: try DevicePublicKey.fake,
            decryptedNonce: "some decrypted nonce",
            metadata: DeviceMetadata.fake,
            signature: try DeviceSignature.fake,
            appAttestation: appAttestation
        )

        let dto = DeviceRegistrationRequestMapper.map(fromDomain: request)

        #expect(dto.payload.devicePublicKey == request.devicePublicKey.derRepresentation.base64EncodedString())
        #expect(dto.payload.nonce == request.decryptedNonce)
        #expect(dto.payload.attestationToken == appAttestation?.object.base64EncodedString())
        #expect(dto.payload.appAttestKeyId == appAttestation?.keyID)
        #expect(dto.payload.metadata.deviceModel == request.metadata.deviceModel)
        #expect(dto.signature == request.signature.derRepresentation.base64EncodedString())
    }
}
