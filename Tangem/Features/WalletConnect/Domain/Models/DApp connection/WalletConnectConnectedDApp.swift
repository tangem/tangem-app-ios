//
//  WalletConnectConnectedDApp.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import struct Foundation.Date
import enum BlockchainSdk.Blockchain

struct WalletConnectConnectedDApp: Hashable {
    let session: WalletConnectDAppSession
    let userWalletID: String
    let dAppData: WalletConnectDAppData
    let verificationStatus: WalletConnectDAppVerificationStatus
    let dAppBlockchains: [WalletConnectDAppBlockchain]
    let connectionDate: Date
}
