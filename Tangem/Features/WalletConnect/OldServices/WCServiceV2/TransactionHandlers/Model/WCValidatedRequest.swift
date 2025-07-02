//
//  WCValidatedRequest.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import ReownWalletKit

struct WCValidatedRequest {
    let request: Request
    let dAppData: WalletConnectDAppData
    let targetBlockchain: WCUtils.BlockchainMeta
    let userWalletModel: UserWalletModel
}
