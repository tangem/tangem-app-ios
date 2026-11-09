//
//  PolymarketOrderPaymentRowModel+Mapping.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemAssets
import TangemPolymarketUI

extension PolymarketOrderPaymentRow.Model {
    static func makeCollateral(balanceText: String) -> Self {
        Self(
            icon: Assets.Polymarket.accountAvatar,
            symbol: AppConstants.usdCurrencyCode,
            balanceText: balanceText
        )
    }
}
