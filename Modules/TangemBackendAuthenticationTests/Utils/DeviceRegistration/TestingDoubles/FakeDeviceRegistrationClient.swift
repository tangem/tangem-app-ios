//
//  FakeDeviceRegistrationClient.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct Foundation.Data
import struct Foundation.Date
@testable import TangemBackendAuthentication

struct FakeDeviceRegistrationClient: DeviceRegistrationClient {
    func requestCipheredNonce(devicePublicKey: DevicePublicKey) throws(DeviceRegistrationClientError) -> String {
        "ciphered-nonce"
    }

    func register(
        devicePublicKey: DevicePublicKey,
        decryptedNonce: String,
        metadata: DeviceMetadata,
        signature: DeviceSignature,
        attestationToken: Data?
    ) throws(DeviceRegistrationClientError) -> SessionTokens {
        SessionTokens(
            accessToken: SessionTokens.Token(jwt: "fake-access-jwt", expiresAt: Date.fake),
            refreshToken: SessionTokens.Token(jwt: "fake-refresh-jwt", expiresAt: Date.fake),
            userWalletIDs: []
        )
    }
}
