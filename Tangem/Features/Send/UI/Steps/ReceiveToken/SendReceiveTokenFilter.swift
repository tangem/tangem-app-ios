//
//  SendReceiveTokenFilter.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk

enum SendReceiveTokenFilter {
    static func isMemoRequiring(receiveTokenBlockchain blockchain: Blockchain) -> Bool {
        switch blockchain {
        case .algorand, .internetComputer, .casper, .xrp, .stellar: true
        default: false
        }
    }
}
