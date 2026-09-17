//
//  PolymarketOrderMarketRowModel+Mapping.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemLocalization
import TangemPolymarket
import TangemPolymarketUI

extension PolymarketOrderMarketRow.Model {
    static func make(market: PolymarketMarket, outcome: PolymarketOutcome, eventTitle: String) -> Self {
        let ownTitle = market.groupItemTitle ?? market.title

        return Self(
            question: ownTitle.isEmpty ? eventTitle : ownTitle,
            imageURL: market.imageURL ?? market.iconURL,
            outcomeTitle: outcome.title,
            outcomePriceText: PolymarketPriceFormatter.centsText(outcome.probability),
            outcomeStyle: PolymarketOutcomeStyle(
                outcomeIndex: market.outcomes.firstIndex { $0.assetId == outcome.assetId } ?? 0
            )
        )
    }
}

// MARK: - From a position

extension PolymarketOrderMarketRow.Model {
    static func make(position: PolymarketPosition) -> Self {
        Self(
            question: position.question ?? Localization.predictionPositionsUnavailable,
            imageURL: position.iconURL,
            outcomeTitle: position.outcome,
            outcomePriceText: PolymarketPriceFormatter.centsText(position.curPrice),
            outcomeStyle: PolymarketOutcomeStyle(binaryOutcomeName: position.outcome)
        )
    }
}
