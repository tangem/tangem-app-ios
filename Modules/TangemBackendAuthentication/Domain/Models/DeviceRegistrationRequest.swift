//
//  DeviceRegistrationRequest.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

struct DeviceRegistrationRequest: Equatable, Sendable {
    let devicePublicKey: DevicePublicKey
    let decryptedNonce: String
    let metadata: DeviceMetadata
    let signature: DeviceSignature
    let appAttestation: AppAttestation?
}
