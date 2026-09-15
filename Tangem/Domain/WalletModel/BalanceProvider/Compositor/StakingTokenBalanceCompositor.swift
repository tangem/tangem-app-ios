//
//  StakingTokenBalanceCompositor.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

/// Staked funds are locked away from the available balance, so the total holds both.
struct StakingTokenBalanceCompositor: TokenBalanceCompositor {
    let balanceProvider: TokenBalanceProvider

    func compose(
        _ composition: TotalTokenBalanceComposition,
        with state: TokenBalanceType
    ) -> TotalTokenBalanceComposition {
        composition.folding(state, combine: +)
    }
}

// MARK: - Factory

extension StakingTokenBalanceCompositor {
    /// Places the staking balance by how the chain accounts for staked funds.
    static func make(balanceProvider: TokenBalanceProvider, tokenItem: TokenItem) -> any TokenBalanceCompositor {
        StakingBlockchainParams(blockchain: tokenItem.blockchain).stakingBalanceRepresentsTotalBalance
            ? CardanoStakingTokenBalanceCompositor(balanceProvider: balanceProvider)
            : StakingTokenBalanceCompositor(balanceProvider: balanceProvider)
    }
}
