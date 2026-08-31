//
//  StubDeviceRegistrationClient.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct Foundation.Data
@testable import TangemBackendAuthentication

struct StubDeviceRegistrationClient: DeviceRegistrationClient {
    var requestCipheredNonceResult: Result<String, DeviceRegistrationClientError> = .success("ciphered-nonce")
    var registerResult: Result<SessionTokens, DeviceRegistrationClientError> = .failure(.alreadyRegistered)

    func requestCipheredNonce(devicePublicKey: DevicePublicKey) throws(DeviceRegistrationClientError) -> String {
        try requestCipheredNonceResult.get()
    }

    func register(
        devicePublicKey: DevicePublicKey,
        decryptedNonce: String,
        metadata: DeviceMetadata,
        signature: DeviceSignature,
        attestationToken: Data?
    ) throws(DeviceRegistrationClientError) -> SessionTokens {
        try registerResult.get()
    }
}
