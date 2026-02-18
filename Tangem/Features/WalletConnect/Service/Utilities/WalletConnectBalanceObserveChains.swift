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
        var chains: [Blockchain] = []

        if FeatureProvider.isAvailable(.walletConnectBitcoin) {
            chains.append(.bitcoin(testnet: false))
            chains.append(.bitcoin(testnet: true))
        }

        return chains
    }
}
