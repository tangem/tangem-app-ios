//
//  UserWalletRegistrationClient.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct Foundation.Data
import struct TangemFoundation.UserWalletId

protocol UserWalletRegistrationClient: Sendable {
    func requestCipheredNonce(devicePublicKey: DevicePublicKey) async throws(UserWalletRegistrationClientError) -> String
    func register(request: UserWalletRegistrationRequest) async throws(UserWalletRegistrationClientError) -> SessionTokens
    func unregister(id: UserWalletId, shouldEraseSocialLoginData: Bool) async throws(UserWalletRegistrationClientError) -> SessionTokens
}
