//
//  SessionAuthenticationRequest.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct Foundation.Data

struct SessionAuthenticationRequest: Equatable, Sendable {
    let devicePublicKey: DevicePublicKey
    let decryptedNonce: String
    let metadata: DeviceMetadata
    let signature: DeviceSignature
    let appAttestToken: Self.AppAttestToken?
}

extension SessionAuthenticationRequest {
    struct AppAttestToken: Equatable, Sendable {
        let keyID: String
        let object: Data

        init(attestation: AppAttestation) {
            keyID = attestation.keyID
            object = attestation.object
        }

        init(assertion: AppAssertion) {
            keyID = assertion.keyID
            object = assertion.object
        }
    }
}
