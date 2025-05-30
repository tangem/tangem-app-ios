//
//  WCConnectionRequestDataItem.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import ReownWalletKit

struct WCConnectionRequestDataItem {
    let accounts: [Account]?
    let blockchainData: WCRequestBlockchainItemDTO

    init(
        accounts: [Account]? = nil,
        blockchainData: WCRequestBlockchainItemDTO
    ) {
        self.accounts = accounts
        self.blockchainData = blockchainData
    }
}
