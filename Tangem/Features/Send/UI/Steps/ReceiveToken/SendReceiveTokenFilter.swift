//
//  SendReceiveTokenFilter.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk

enum SendReceiveTokenFilter {
    static func isSupported(receiveTokenBlockchain blockchain: Blockchain) -> Bool {
        switch blockchain {
        // Express providers work incorrectly with MEMO in these networks.
        // We decided not to allow users to select this option
        case .algorand, .internetComputer, .casper: false
        default: true
        }
    }
}
