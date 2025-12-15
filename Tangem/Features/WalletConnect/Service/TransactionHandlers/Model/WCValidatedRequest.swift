//
//  WCValidatedRequest.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import struct ReownWalletKit.Request
import enum BlockchainSdk.Blockchain

struct WCValidatedRequest {
    let request: ReownWalletKit.Request
    let dAppData: WalletConnectDAppData
    let targetBlockchain: Blockchain
    let userWalletModel: UserWalletModel
    let account: (any CryptoAccountModel)?
}
