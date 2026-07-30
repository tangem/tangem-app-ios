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
    struct Model {
        let title: String
        let volumeText: String?
        let imageURL: URL?
        let predictedText: String?
        let outcomes: [Outcome]
    }

    struct Outcome: Identifiable {
        enum Style {
            case affirmative
            case negative
            case neutral
        }

        let id: String
        let title: String
        let priceText: String
        let style: Style
        let onSelect: () -> Void
    }
}

// MARK: - Domain mapping

extension PolymarketMarketCard.Model {
    static func make(
        market: PolymarketMarket,
        predictedText: String? = nil,
        onSelectOutcome: @escaping (PolymarketOutcome) -> Void
    ) -> Self {
        Self(
            title: market.groupItemTitle ?? market.title,
            volumeText: market.volume.map(volumeFormatter.formatMarketCap),
            imageURL: market.imageURL ?? market.iconURL,
            predictedText: predictedText,
            outcomes: market.outcomes.map { outcome in
                PolymarketMarketCard.Outcome(
                    id: outcome.assetId,
                    title: outcome.title,
                    priceText: outcome.probability.map(centsText) ?? "—",
                    style: PolymarketMarketCard.Outcome.Style(outcomeTitle: outcome.title),
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

    private static func centsText(_ probability: Decimal) -> String {
        var value = probability * 100
        var cents = Decimal()
        NSDecimalRound(&cents, &value, 0, .plain)
        return "\(NSDecimalNumber(decimal: cents).intValue)¢"
    }
}

private extension PolymarketMarketCard.Outcome.Style {
    init(outcomeTitle: String) {
        switch outcomeTitle.lowercased() {
        case "yes": self = .affirmative
        case "no": self = .negative
        default: self = .neutral
        }
    }
}
