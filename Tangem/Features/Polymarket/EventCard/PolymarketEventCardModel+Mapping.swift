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
    static func displayedMarkets(of event: PolymarketEvent) -> ArraySlice<PolymarketMarket> {
        event.markets.prefix(MappingConstants.maxDisplayedMarkets)
    }

    static func make(
        event: PolymarketEvent,
        category: PolymarketCategory?,
        isInActivePredicts: Bool,
        liveQuotesByAssetId: [String: PolymarketOutcomeQuote] = [:],
        onSelectOutcome: @escaping (PolymarketMarket, PolymarketOutcome) -> Void
    ) -> Self {
        let variant: PolymarketEventCard.Variant = event.totalMarketsCount > 1 ? .multiMarket : .singleMarket

        let rows = displayedMarkets(of: event).map { market in
            makeRow(market: market, event: event, liveQuotesByAssetId: liveQuotesByAssetId, onSelectOutcome: onSelectOutcome)
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
            isInActivePredicts: isInActivePredicts,
            isLive: event.isLive
        )
    }

    private static func makeRow(
        market: PolymarketMarket,
        event: PolymarketEvent,
        liveQuotesByAssetId: [String: PolymarketOutcomeQuote],
        onSelectOutcome: @escaping (PolymarketMarket, PolymarketOutcome) -> Void
    ) -> PolymarketEventCard.Row {
        let title = market.listLabel
        let subtitle = title.map { _ in rowPercentText(market: market, liveQuotesByAssetId: liveQuotesByAssetId) }

        let outcomeTitles = event.buttonTitles(for: market)

        let outcomes = market.outcomes.enumerated().map { index, outcome in
            PolymarketEventCard.Outcome(
                id: outcome.assetId,
                title: outcomeTitles[index],
                priceText: title == nil ? buttonPriceText(outcome: outcome, liveQuote: liveQuotesByAssetId[outcome.assetId]) : nil,
                style: PolymarketOutcomeStyle(outcomeIndex: index),
                onSelect: { onSelectOutcome(market, outcome) }
            )
        }

        return PolymarketEventCard.Row(id: market.id, title: title, subtitle: subtitle, outcomes: outcomes)
    }

    private static func buttonPriceText(outcome: PolymarketOutcome, liveQuote: PolymarketOutcomeQuote?) -> String {
        guard let liveQuote else {
            return PolymarketPriceFormatter.centsText(outcome.probability)
        }

        return PolymarketPriceFormatter.centsText(liveQuote.bestAsk)
    }

    private static func rowPercentText(market: PolymarketMarket, liveQuotesByAssetId: [String: PolymarketOutcomeQuote]) -> String {
        let yesOutcome = market.outcomes.first
        let liveProbability = yesOutcome
            .flatMap { liveQuotesByAssetId[$0.assetId] }
            .flatMap(liveProbability(of:))

        return PolymarketPriceFormatter.percentText(liveProbability ?? yesOutcome?.probability)
    }

    private static func liveProbability(of quote: PolymarketOutcomeQuote) -> Decimal? {
        guard let bestBid = quote.bestBid,
              let bestAsk = quote.bestAsk,
              bestAsk - bestBid <= MappingConstants.maxMidpointSpread else {
            return quote.lastTradePrice
        }

        return (bestBid + bestAsk) / 2
    }
}

// MARK: - Constants

private extension PolymarketEventCard.Model {
    enum MappingConstants {
        static let maxDisplayedMarkets = 2
        static let maxMidpointSpread: Decimal = 0.1

        static let volumeFormatter = MarketCapFormatter(
            divisorsList: AmountNotationSuffixFormatter.Divisor.defaultList,
            baseCurrencyCode: AppConstants.usdCurrencyCode,
            notationFormatter: DefaultAmountNotationFormatter()
        )
    }
}
