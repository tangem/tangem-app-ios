//
//  DeviceRegistrationClient.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

protocol DeviceRegistrationClient: Sendable {
    func requestCipheredNonce(devicePublicKey: DevicePublicKey) async throws(DeviceRegistrationClientError) -> String
    func register(request: DeviceRegistrationRequest) async throws(DeviceRegistrationClientError) -> SessionTokens
}
