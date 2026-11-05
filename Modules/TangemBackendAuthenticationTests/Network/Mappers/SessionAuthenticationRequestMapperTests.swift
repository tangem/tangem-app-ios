//
//  SessionAuthenticationRequestMapperTests.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import TangemBackendAuthentication

@Suite(.tags(.backendAuthentication))
struct SessionAuthenticationRequestMapperTests {
    @Test(arguments: Self.appAttestTokens)
    func mapFromDomainProducesCorrectAuthenticateDTORequest(appAttestToken: SessionAuthenticationRequest.AppAttestToken?) throws {
        let request = SessionAuthenticationRequest(
            devicePublicKey: try DevicePublicKey.fake,
            decryptedNonce: "some decrypted nonce",
            metadata: DeviceMetadata.fake,
            signature: try DeviceSignature.fake,
            appAttestToken: appAttestToken
        )

        let dto = SessionAuthenticationRequestMapper.map(fromDomain: request)

        #expect(dto.payload.devicePublicKey == request.devicePublicKey.derRepresentation.base64EncodedString())
        #expect(dto.payload.nonce == request.decryptedNonce)
        #expect(dto.payload.attestationToken == appAttestToken?.object.base64EncodedString())
        #expect(dto.payload.appAttestKeyId == appAttestToken?.keyID)
        #expect(dto.payload.metadata.deviceModel == request.metadata.deviceModel)
        #expect(dto.signature == request.signature.derRepresentation.base64EncodedString())
    }
}

extension SessionAuthenticationRequestMapperTests {
    private static let tokenFromAttestation = SessionAuthenticationRequest.AppAttestToken(attestation: AppAttestation.fake)
    private static let tokenFromAssertion = SessionAuthenticationRequest.AppAttestToken(assertion: AppAssertion.fake)

    static let appAttestTokens: [SessionAuthenticationRequest.AppAttestToken?] = [
        Self.tokenFromAttestation,
        Self.tokenFromAssertion,
        nil,
    ]
}
