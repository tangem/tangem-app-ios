//
//  PolymarketOrderSummaryHeaderModel+Mapping.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemAssets
import TangemLocalization
import TangemPolymarket
import TangemPolymarketUI

extension PolymarketOrderSummaryHeader.Model {
    static func make(amountText: String, balanceText: String, toWin: PolymarketAmountBadge.State?) -> Self {
        Self(
            accountName: Localization.predictionPlaceSummaryAccount,
            accountIcon: Assets.Polymarket.logo,
            balanceText: balanceText,
            amountText: amountText,
            toWin: toWin,
            tokenIconInfo: TokenIconInfoBuilder().build(from: PolymarketUtilities.collateralTokenItem, isCustom: false)
        )
    }
}
