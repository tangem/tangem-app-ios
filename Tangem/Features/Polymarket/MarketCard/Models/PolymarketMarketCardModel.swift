//
//  PolymarketMarketCardModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemPolymarket

extension PolymarketMarketCard {
    struct Model: Identifiable {
        let id: String
        let title: String
        let volumeText: String?
        let imageURL: URL?
        let predictedText: String?
        let outcomes: [Outcome]
    }

    struct Outcome: Identifiable {
        let id: String
        let title: String
        let priceText: String
        let style: PolymarketOutcomeStyle
        let onSelect: () -> Void
    }
}

// MARK: - Domain mapping

extension PolymarketMarketCard.Model {
    static func make(
        market: PolymarketMarket,
        title: String? = nil,
        fallbackImageURL: URL? = nil,
        predictedText: String? = nil,
        showsOutcomes: Bool = true,
        onSelectOutcome: @escaping (PolymarketOutcome) -> Void
    ) -> Self {
        Self(
            id: market.id,
            title: title ?? market.groupItemTitle ?? market.title,
            volumeText: market.volume.map(volumeFormatter.formatMarketCap),
            imageURL: market.imageURL ?? market.iconURL ?? fallbackImageURL,
            predictedText: predictedText,
            outcomes: showsOutcomes ? market.outcomes.enumerated().map { index, outcome in
                PolymarketMarketCard.Outcome(
                    id: outcome.assetId,
                    title: outcome.title,
                    priceText: PolymarketPriceFormatter.centsText(outcome.probability),
                    style: PolymarketOutcomeStyle(outcomeIndex: index),
                    onSelect: { onSelectOutcome(outcome) }
                )
            } : []
        )
    }

    private static let volumeFormatter = MarketCapFormatter(
        divisorsList: AmountNotationSuffixFormatter.Divisor.defaultList,
        baseCurrencyCode: AppConstants.usdCurrencyCode,
        notationFormatter: DefaultAmountNotationFormatter()
    )
}
