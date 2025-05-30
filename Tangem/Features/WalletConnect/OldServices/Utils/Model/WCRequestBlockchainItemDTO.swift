//
//  WCRequestBlockchainItemDTO.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import ReownWalletKit

struct WCRequestBlockchainItemDTO {
    let wcBlockchain: WalletConnectUtils.Blockchain
    let state: WCSelectBlockchainItemState
}
