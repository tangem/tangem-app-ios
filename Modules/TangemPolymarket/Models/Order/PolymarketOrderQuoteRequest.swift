//
//  PolymarketOrderQuoteRequest.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct PolymarketOrderQuoteRequest: Hashable, Sendable {
    public let marketId: String
    public let assetId: String
    public let side: PolymarketOrderSide

    /// Collateral to spend when buying, shares to sell when selling.
    public let amount: Decimal

    /// Always sent: the screen shows the tolerance it applies, so the backend must not substitute its own default.
    public let slippagePercent: Decimal

    public init(
        marketId: String,
        assetId: String,
        side: PolymarketOrderSide,
        amount: Decimal,
        slippagePercent: Decimal
    ) {
        self.marketId = marketId
        self.assetId = assetId
        self.side = side
        self.amount = amount
        self.slippagePercent = slippagePercent
    }
}
