//
//  WalletConnectBalanceObserveChains.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import enum BlockchainSdk.Blockchain

enum WalletConnectBalanceObserveChains {
    static func chains() -> [Blockchain] {
        [
            .bitcoin(testnet: false),
            .bitcoin(testnet: true),
        ]
    }
}
