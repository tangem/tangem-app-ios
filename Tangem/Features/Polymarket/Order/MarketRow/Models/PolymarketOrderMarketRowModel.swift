//
//  PolymarketOrderMarketRowModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemPolymarket

extension PolymarketOrderMarketRow {
    struct Model {
        let question: String
        let imageURL: URL?
        let outcomeTitle: String
        let outcomePriceText: String
        let outcomeStyle: PolymarketOutcomeStyle
    }
}

// MARK: - Domain mapping

extension PolymarketOrderMarketRow.Model {
    static func make(market: PolymarketMarket, outcomeIndex: Int) -> Self {
        let outcome = market.outcomes[outcomeIndex]

        return Self(
            question: market.groupItemTitle ?? market.title,
            imageURL: market.imageURL ?? market.iconURL,
            outcomeTitle: outcome.title,
            outcomePriceText: PolymarketPriceFormatter.centsText(outcome.probability),
            outcomeStyle: PolymarketOutcomeStyle(outcomeIndex: outcomeIndex)
        )
    }
}
