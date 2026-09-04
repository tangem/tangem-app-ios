//
//  DeviceRegistrationClient.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct Foundation.Data

protocol DeviceRegistrationClient: Sendable {
    func requestCipheredNonce(devicePublicKey: DevicePublicKey) async throws(DeviceRegistrationClientError) -> String

    func register(
        devicePublicKey: DevicePublicKey,
        decryptedNonce: String,
        metadata: DeviceMetadata,
        signature: DeviceSignature,
        attestationToken: Data?
    ) async throws(DeviceRegistrationClientError) -> SessionTokens
}
