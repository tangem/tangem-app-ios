//
//  PolymarketPosition+MarketMatch.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public extension PolymarketPosition {
    struct MarketMatch: Hashable, Sendable {
        public let market: PolymarketMarket
        public let outcome: PolymarketOutcome
    }

    func marketMatch(in markets: [PolymarketMarket]) -> MarketMatch? {
        if let market = owningMarket(in: markets),
           let outcomeIndex,
           market.outcomes.indices.contains(outcomeIndex) {
            return MarketMatch(market: market, outcome: market.outcomes[outcomeIndex])
        }

        for market in markets {
            if let outcome = market.outcomes.first(where: holdsToken) {
                return MarketMatch(market: market, outcome: outcome)
            }
        }

        return nil
    }
}

public extension PolymarketPosition {
    func isTradable(as outcome: PolymarketOutcome) -> Bool {
        outcome.assetId == assetId
    }
}

// MARK: - Private implementation

private extension PolymarketPosition {
    func owningMarket(in markets: [PolymarketMarket]) -> PolymarketMarket? {
        if let marketId, let market = markets.first(where: { $0.id == marketId }) {
            return market
        }

        return markets.first { market in
            market.conditionId?.caseInsensitiveCompare(conditionId) == .orderedSame
        }
    }

    func holdsToken(_ outcome: PolymarketOutcome) -> Bool {
        outcome.assetId == assetId || outcome.legacyAssetId == assetId
    }
}
