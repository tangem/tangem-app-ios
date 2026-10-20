//
//  PolymarketEventCardModel+Mapping.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemPolymarket
import TangemPolymarketUI

extension PolymarketEventCard.Model {
    static func make(
        event: PolymarketEvent,
        category: PolymarketCategory?,
        isInActivePredicts: Bool,
        onSelectOutcome: @escaping (PolymarketMarket, PolymarketOutcome) -> Void
    ) -> Self {
        let variant: PolymarketEventCard.Variant = event.totalMarketsCount > 1 ? .multiMarket : .singleMarket

        let rows = event.markets.prefix(MappingConstants.maxDisplayedMarkets).map { market in
            makeRow(market: market, onSelectOutcome: onSelectOutcome)
        }

        return PolymarketEventCard.Model(
            id: event.id,
            title: event.title,
            category: category.map { .init(name: $0.label, icon: $0.icon?.badgeImage) },
            volumeText: event.volume.map { MappingConstants.volumeFormatter.formatMarketCap($0) },
            imageURL: event.iconURL ?? event.imageURL,
            variant: variant,
            rows: rows,
            additionalOutcomesCount: max(0, event.totalMarketsCount - rows.count),
            isInActivePredicts: isInActivePredicts
        )
    }

    private static func makeRow(
        market: PolymarketMarket,
        onSelectOutcome: @escaping (PolymarketMarket, PolymarketOutcome) -> Void
    ) -> PolymarketEventCard.Row {
        let title = market.listLabel
        let subtitle = title.map { _ in PolymarketPriceFormatter.percentText(market.outcomes.first?.probability) }

        let outcomes = market.outcomes.enumerated().map { index, outcome in
            PolymarketEventCard.Outcome(
                id: outcome.assetId,
                title: outcome.title,
                priceText: title == nil ? PolymarketPriceFormatter.centsText(outcome.probability) : nil,
                style: PolymarketOutcomeStyle(outcomeIndex: index),
                onSelect: { onSelectOutcome(market, outcome) }
            )
        }

        return PolymarketEventCard.Row(id: market.id, title: title, subtitle: subtitle, outcomes: outcomes)
    }
}

// MARK: - Constants

private extension PolymarketEventCard.Model {
    enum MappingConstants {
        static let maxDisplayedMarkets = 2

        static let volumeFormatter = MarketCapFormatter(
            divisorsList: AmountNotationSuffixFormatter.Divisor.defaultList,
            baseCurrencyCode: AppConstants.usdCurrencyCode,
            notationFormatter: DefaultAmountNotationFormatter()
        )
    }
}
