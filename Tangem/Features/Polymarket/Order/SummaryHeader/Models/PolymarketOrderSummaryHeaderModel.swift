//
//  PolymarketOrderSummaryHeaderModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemAssets
import TangemUI

extension PolymarketOrderSummaryHeader {
    struct Model {
        let accountName: String
        let accountIcon: ImageType
        let balanceText: String
        let amountText: String
        let toWin: PolymarketToWinBadge.State
        let tokenIconInfo: TokenIconInfo
    }
}
