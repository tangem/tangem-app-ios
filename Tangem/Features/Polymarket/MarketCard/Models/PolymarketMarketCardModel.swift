//
//  PolymarketMarketCardModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
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
        enum Style {
            case affirmative
            case negative
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
                    priceText: outcome.probability.map(centsText) ?? .emDashSign,
                    style: PolymarketMarketCard.Outcome.Style(outcomeIndex: index),
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

    private static func centsText(_ probability: Decimal) -> String {
        var value = probability * 100
        var cents = Decimal()
        NSDecimalRound(&cents, &value, 0, .plain)
        return "\(NSDecimalNumber(decimal: cents).intValue)¢"
    }
}

private extension PolymarketMarketCard.Outcome.Style {
    init(outcomeIndex: Int) {
        self = outcomeIndex == 0 ? .affirmative : .negative
    }
}
