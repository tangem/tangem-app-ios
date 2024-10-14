//
//  HederaAccountBalance.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct HederaAccountBalance {
    struct TokenBalance {
        let contractAddress: String
        /// In atomic units.
        let balance: Int
        let decimalCount: Int
    }

    /// In atomic units (i.e. Tinybars).
    let hbarBalance: Int
    let tokenBalances: [TokenBalance]
}
