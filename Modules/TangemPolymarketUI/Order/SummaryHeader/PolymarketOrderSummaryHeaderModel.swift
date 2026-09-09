//
//  PolymarketOrderSummaryHeaderModel.swift
//  TangemPolymarketUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemAssets
import TangemUI

public extension PolymarketOrderSummaryHeader {
    struct Model {
        public let accountName: String
        public let accountIcon: ImageType
        public let balanceText: String
        public let amountText: String
        public let toWin: PolymarketAmountBadge.State?
        public let tokenIconInfo: TokenIconInfo

        public init(
            accountName: String,
            accountIcon: ImageType,
            balanceText: String,
            amountText: String,
            toWin: PolymarketAmountBadge.State?,
            tokenIconInfo: TokenIconInfo
        ) {
            self.accountName = accountName
            self.accountIcon = accountIcon
            self.balanceText = balanceText
            self.amountText = amountText
            self.toWin = toWin
            self.tokenIconInfo = tokenIconInfo
        }
    }
}
