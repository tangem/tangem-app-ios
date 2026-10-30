//
//  PolymarketOutcomeQuote.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct PolymarketOutcomeQuote: Hashable, Sendable {
    public let assetId: String
    public let bestBid: Decimal?
    public let bestAsk: Decimal?
    public let lastTradePrice: Decimal?
    public let updatedAt: Date?

    public init(assetId: String, bestBid: Decimal?, bestAsk: Decimal?, lastTradePrice: Decimal?, updatedAt: Date?) {
        self.assetId = assetId
        self.bestBid = bestBid
        self.bestAsk = bestAsk
        self.lastTradePrice = lastTradePrice
        self.updatedAt = updatedAt
    }
}
