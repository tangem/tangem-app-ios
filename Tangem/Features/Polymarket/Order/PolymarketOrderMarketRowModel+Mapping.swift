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
    static func make(
        market: PolymarketMarket,
        outcome: PolymarketOutcome,
        eventTitle: String,
        averagePrice: Decimal? = nil
    ) -> Self {
        let ownTitle = market.title.nilIfEmpty ?? market.groupItemTitle?.nilIfEmpty

        return Self(
            question: ownTitle ?? eventTitle,
            imageURL: market.imageURL ?? market.iconURL,
            outcomeTitle: outcome.title,
            outcomePriceText: PolymarketPriceFormatter.centsText(averagePrice ?? outcome.probability),
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
            outcomeStyle: PolymarketOutcomeStyle(outcomeIndex: position.outcomeIndex, name: position.outcome)
        )
    }
}
