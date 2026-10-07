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
    static func make(
        account: PolymarketOrderAccount?,
        sourceTitle: String,
        amountText: String,
        balanceText: String,
        toWin: PolymarketAmountBadge.State?,
        caption: String?
    ) -> Self {
        Self(
            accountName: account?.name ?? Localization.predictionPlaceSummaryAccount,
            accountIcon: account?.icon ?? Assets.Polymarket.accountAvatar,
            sourceTitle: sourceTitle,
            balanceText: balanceText,
            amountText: amountText,
            toWin: toWin,
            caption: caption,
            tokenIconInfo: TokenIconInfoBuilder().build(from: PolymarketUtilities.collateralTokenItem, isCustom: false)
        )
    }
}
