//
//  UserWalletRecoveryClient.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

protocol UserWalletRecoveryClient: Sendable {
    func requestCipheredNonce(devicePublicKey: DevicePublicKey) async throws(UserWalletRecoveryClientError) -> String
}
