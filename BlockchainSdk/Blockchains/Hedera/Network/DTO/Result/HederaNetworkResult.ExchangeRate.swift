//
//  HederaNetworkResult.ExchangeRate.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

extension HederaNetworkResult {
    struct ExchangeRate: Decodable {
        struct Rate: Decodable {
            var centEquivalent: Int
            var hbarEquivalent: Int
            var expirationTime: Int
        }

        let currentRate: Rate
        let nextRate: Rate
        let timestamp: String
    }
}
