//
//  TokenItem+StakingTokenItem.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking

extension TokenItem {
    var stakingTokenItem: TangemStaking.StakingTokenItem {
        StakingTokenItem(
            coinId: id ?? blockchain.coinId,
            contractAddress: contractAddress
        )
    }
}
