//
//  PolymarketEventCard+Model.swift
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
            makeRow(market: market, variant: variant, onSelectOutcome: onSelectOutcome)
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
        variant: PolymarketEventCard.Variant,
        onSelectOutcome: @escaping (PolymarketMarket, PolymarketOutcome) -> Void
    ) -> PolymarketEventCard.Row {
        let title = variant == .singleMarket
            ? MappingConstants.singleMarketRowTitle
            : (market.groupItemTitle ?? market.title)

        let affirmative = market.outcomes.first { $0.title.caseInsensitiveCompare(MappingConstants.affirmativeOutcomeTitle) == .orderedSame }
        let probability = (affirmative ?? market.outcomes.first)?.probability
        let subtitle = probability.map(formatProbability) ?? ""

        let outcomes = market.outcomes.map { outcome in
            let isAffirmative = outcome.title.caseInsensitiveCompare(MappingConstants.affirmativeOutcomeTitle) == .orderedSame
            return PolymarketEventCard.Outcome(
                id: outcome.assetId,
                title: outcome.title,
                style: isAffirmative ? .affirmative : .negative,
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

        // [REDACTED_TODO_COMMENT]
        static let singleMarketRowTitle = "Probability"

        static let affirmativeOutcomeTitle = "Yes"

        static let volumeFormatter = MarketCapFormatter(
            divisorsList: AmountNotationSuffixFormatter.Divisor.defaultList,
            baseCurrencyCode: "USD",
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
