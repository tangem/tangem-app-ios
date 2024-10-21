//
//  HederaNetworkResult.TransactionsInfo.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

extension HederaNetworkResult {
    /// Used by the Mirror network layer.
    struct TransactionsInfo: Decodable {
        struct Transaction: Decodable {
            let result: String
            let transactionId: String
        }

        let transactions: [Transaction]
    }
}
