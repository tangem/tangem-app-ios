//
//  WalletConnectConnectedDApp.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import struct Foundation.Date
import enum BlockchainSdk.Blockchain

struct WalletConnectConnectedDApp: Equatable {
    let session: WalletConnectDAppSession
    let userWalletID: String
    let dAppData: WalletConnectDAppData
    let verificationStatus: WalletConnectDAppVerificationStatus
    let blockchains: [Blockchain]
    let connectionDate: Date
}
