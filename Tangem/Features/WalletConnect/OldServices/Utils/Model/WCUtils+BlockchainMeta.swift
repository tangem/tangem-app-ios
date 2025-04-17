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
    }
}

extension WCUtils.BlockchainMeta {
    init?(from blockchain: BlockchainSdk.Blockchain?) {
        if let blockchain {
            id = blockchain.networkId
            currencySymbol = blockchain.currencySymbol
            displayName = blockchain.displayName
        } else {
            return nil
        }
    }
}
