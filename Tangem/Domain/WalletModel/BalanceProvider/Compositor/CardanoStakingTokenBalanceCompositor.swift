//
//  CardanoStakingTokenBalanceCompositor.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Cardano doesn't lock staked funds, so its staking balance already covers the available balance plus
/// rewards and stands in for the total. A zero staked amount means staking is off and the base stands.
struct CardanoStakingTokenBalanceCompositor: TokenBalanceCompositor {
    let balanceProvider: TokenBalanceProvider

    func compose(
        _ composition: TotalTokenBalanceComposition,
        with state: TokenBalanceType
    ) -> TotalTokenBalanceComposition {
        composition.folding(state) { total, staked in
            staked.isZero ? total : staked
        }
    }
}
