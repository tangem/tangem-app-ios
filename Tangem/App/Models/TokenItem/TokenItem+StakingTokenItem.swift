//
//  TokenItem+StakingTokenItem.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking
import BlockchainSdk

extension TokenItem {
    var stakingTokenItem: TangemStaking.StakingTokenItem? {
        StakeKitNetworkType(rawValue: blockchain.stakeKitNetworkID).map { network in
            StakingTokenItem(
                network: network,
                contractAddress: contractAddress,
                name: name,
                decimals: decimalCount,
                symbol: currencySymbol
            )
        }
    }
}

private extension Blockchain {
    var stakeKitNetworkID: String {
        switch self {
        case .bsc: "binance"
        case .avalanche: "avalanche-c"
        default: coinId
        }
    }
}
