//
//  PolymarketQuoteStatus.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public enum PolymarketQuoteStatus: String, Hashable, Sendable {
    case full = "FULL"
    case partial = "PARTIAL"
    case insufficientLiquidity = "INSUFFICIENT_LIQUIDITY"
    case belowMinOrderSize = "BELOW_MIN_ORDER_SIZE"
    case belowMinOrderAmount = "BELOW_MIN_ORDER_AMOUNT"
    case marketClosed = "MARKET_CLOSED"

    case undefined = "UNDEFINED"

    public var isPlaceable: Bool {
        self == .full || self == .partial
    }
}
