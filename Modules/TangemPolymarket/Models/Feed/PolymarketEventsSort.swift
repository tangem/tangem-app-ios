//
//  PolymarketEventsSort.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public enum PolymarketEventsSort: String, Hashable, Sendable {
    case volume
    case volume24h = "volume24hr"
    case liquidity
    case endDate
}
