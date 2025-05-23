//
//  WCUtils+BlockchainMeta.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import BlockchainSdk

extension WCUtils {
    struct BlockchainMeta {
        let id: String
        let currencySymbol: String
        let displayName: String

        init(from blockchain: BlockchainSdk.Blockchain) {
            id = blockchain.networkId
            currencySymbol = blockchain.currencySymbol
            displayName = blockchain.displayName
        }
    }
}
