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
        StakingNetworkType(rawValue: blockchain.networkId).map { network in
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
