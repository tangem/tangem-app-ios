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
            makeRow(market: market, in: event, onSelectOutcome: onSelectOutcome)
        }

        return PolymarketEventCard.Model(
            id: event.id,
            title: event.title,
            category: category.map { .init(name: $0.label, iconURL: $0.iconURL) },
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
        in event: PolymarketEvent,
        onSelectOutcome: @escaping (PolymarketMarket, PolymarketOutcome) -> Void
    ) -> PolymarketEventCard.Row {
        let title = switch event.displayMode {
        case .groupedOutcomes: market.groupItemTitle ?? market.title
        case .plainMarkets: market.title
        }
        let subtitle = PolymarketPriceFormatter.percentText(market.outcomes.first?.probability)

        let outcomes = market.outcomes.enumerated().map { index, outcome in
            PolymarketEventCard.Outcome(
                id: outcome.assetId,
                title: outcome.title,
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
