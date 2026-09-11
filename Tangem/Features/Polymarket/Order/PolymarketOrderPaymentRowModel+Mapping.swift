//
//  PolymarketOrderPaymentRowModel+Mapping.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemAssets
import TangemPolymarket
import TangemPolymarketUI

extension PolymarketOrderPaymentRow.Model {
    static func makeCollateral(balanceText: String) -> Self {
        let tokenItem = PolymarketUtilities.collateralTokenItem

        return Self(
            tokenIconInfo: TokenIconInfoBuilder().build(from: tokenItem, isCustom: false),
            symbol: tokenItem.currencySymbol,
            balanceText: balanceText
        )
    }
}
