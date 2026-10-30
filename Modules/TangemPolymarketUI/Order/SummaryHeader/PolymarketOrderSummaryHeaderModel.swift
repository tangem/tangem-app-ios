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
        public let sourceTitle: String
        public let balanceText: String
        public let amountText: String
        public let toWin: PolymarketAmountBadge.State?
        public let caption: String?

        public init(
            accountName: String,
            accountIcon: ImageType,
            sourceTitle: String,
            balanceText: String,
            amountText: String,
            toWin: PolymarketAmountBadge.State?,
            caption: String? = nil
        ) {
            self.accountName = accountName
            self.accountIcon = accountIcon
            self.sourceTitle = sourceTitle
            self.balanceText = balanceText
            self.amountText = amountText
            self.toWin = toWin
            self.caption = caption
        }
    }
}
