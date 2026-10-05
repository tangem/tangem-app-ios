//
//  PolymarketMarketCardModel+Mapping.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemPolymarket
import TangemPolymarketUI

extension PolymarketMarketCard.Model {
    static func make(
        market: PolymarketMarket,
        title: String?,
        fallbackImageURL: URL? = nil,
        predictedText: String? = nil,
        areOutcomesEnabled: Bool = true,
        onSelectOutcome: @escaping (PolymarketOutcome) -> Void
    ) -> Self {
        Self(
            id: market.id,
            title: title,
            volumeText: market.volume.map(volumeFormatter.formatMarketCap) ?? BalanceFormatter.defaultEmptyBalanceString,
            imageURL: market.imageURL ?? market.iconURL ?? fallbackImageURL,
            predictedText: predictedText,
            outcomes: market.outcomes.enumerated().map { index, outcome in
                PolymarketMarketCard.Outcome(
                    id: outcome.assetId,
                    title: outcome.title,
                    priceText: PolymarketPriceFormatter.centsText(outcome.probability, isResolved: market.status == .closed),
                    style: PolymarketOutcomeStyle(outcomeIndex: index),
                    isEnabled: areOutcomesEnabled,
                    onSelect: { onSelectOutcome(outcome) }
                )
            }
        )
    }

    private static let volumeFormatter = MarketCapFormatter(
        divisorsList: AmountNotationSuffixFormatter.Divisor.defaultList,
        baseCurrencyCode: AppConstants.usdCurrencyCode,
        notationFormatter: DefaultAmountNotationFormatter()
    )
}
