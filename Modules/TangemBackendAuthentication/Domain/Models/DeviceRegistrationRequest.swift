//
//  DeviceRegistrationRequest.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct Foundation.Data

struct DeviceRegistrationRequest: Equatable, Sendable {
    let devicePublicKey: DevicePublicKey
    let decryptedNonce: String
    let metadata: DeviceMetadata
    let signature: DeviceSignature
    let appAttestationToken: Data?
}
