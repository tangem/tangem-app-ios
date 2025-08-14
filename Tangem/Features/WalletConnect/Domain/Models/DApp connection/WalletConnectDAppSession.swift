//
//  WalletConnectDAppSession.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import struct Foundation.Date
import enum BlockchainSdk.Blockchain

struct WalletConnectDAppSession: Hashable {
    let topic: String
    let expiryDate: Date
}
