//
//  TokenBalanceCompositor.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// One balance source joining the total after the base (available) balance.
///
/// `TotalTokenBalanceComposition.folding(_:combine:)` does the bookkeeping every source shares. A compositor
/// that substitutes rather than adds has to precede the ones that add, or it discards their contributions.
protocol TokenBalanceCompositor {
    var balanceProvider: TokenBalanceProvider { get }

    func compose(
        _ composition: TotalTokenBalanceComposition,
        with state: TokenBalanceType
    ) -> TotalTokenBalanceComposition
}
