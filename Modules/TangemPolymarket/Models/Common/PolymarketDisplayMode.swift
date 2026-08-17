//
//  PolymarketDisplayMode.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public enum PolymarketDisplayMode: Hashable, Sendable {
    case groupedOutcomes
    case plainMarkets

    public init(apiValue: String) {
        switch apiValue {
        case "grouped_outcomes": self = .groupedOutcomes
        default: self = .plainMarkets
        }
    }
}
