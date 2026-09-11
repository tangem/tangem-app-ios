//
//  PolymarketEventCardModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemPolymarket

extension PolymarketEventCard {
    enum Variant: Hashable {
        case multiMarket
        case singleMarket
    }

    struct Model {
        let id: String
        let title: String
        let category: Category?
        let volumeText: String?
        let imageURL: URL?
        let variant: Variant
        let rows: [Row]
        let additionalOutcomesCount: Int
        let isInActivePredicts: Bool
    }

    struct Category {
        let name: String
        let iconURL: URL?
    }

    struct Row: Identifiable {
        let id: String
        let title: String
        let subtitle: String
        let outcomes: [Outcome]
    }

    struct Outcome: Identifiable {
        enum Style: Hashable {
            case affirmative
            case negative
        }

        let id: String
        let title: String
        let style: Style
        let onSelect: () -> Void
    }
}

// MARK: - Domain mapping

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
            category: category.map { .init(name: $0.label, iconURL: $0.iconURL) },
            volumeText: event.volume.map { MappingConstants.volumeFormatter.formatMarketCap($0) },
            imageURL: event.imageURL ?? event.iconURL,
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
        let title = market.groupItemTitle ?? market.title

        let probability = market.outcomes.first?.probability
        let subtitle = probability.map(formatProbability) ?? ""

        // Upstream labels are not always "Yes"/"No", so the affirmative outcome is the first one by position
        let outcomes = market.outcomes.enumerated().map { index, outcome in
            PolymarketEventCard.Outcome(
                id: outcome.assetId,
                title: outcome.title,
                style: index == 0 ? .affirmative : .negative,
                onSelect: { onSelectOutcome(market, outcome) }
            )
        }

        return PolymarketEventCard.Row(id: market.id, title: title, subtitle: subtitle, outcomes: outcomes)
    }

    private static func formatProbability(_ probability: Decimal) -> String {
        MappingConstants.probabilityFormatter.string(from: probability as NSDecimalNumber) ?? ""
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

        static let probabilityFormatter: NumberFormatter = {
            let formatter = NumberFormatter()
            formatter.numberStyle = .percent
            formatter.maximumFractionDigits = 0
            return formatter
        }()
    }
}
