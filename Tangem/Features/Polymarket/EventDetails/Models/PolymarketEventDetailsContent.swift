//
//  PolymarketEventDetailsContent.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemPolymarket
import TangemPolymarketUI

struct PolymarketEventDetailsContent {
    let iconURL: URL?
    let title: String
    let isLive: Bool
    let categoryName: String?
    let volumeText: String?
    let activeMarkets: [PolymarketMarketCard.Model]
    let closedMarkets: [PolymarketMarketCard.Model]
    let description: String?
    let resolutionDateText: String?
    let marketOpenedDateText: String?

    var hasMeta: Bool {
        isLive || categoryName != nil || volumeText != nil
    }

    var hasInfoRows: Bool {
        resolutionDateText != nil || marketOpenedDateText != nil
    }
}

// MARK: - Domain mapping

extension PolymarketEventDetailsContent {
    static func make(
        event: PolymarketEvent,
        category: PolymarketCategory?,
        onSelectOutcome: @escaping (PolymarketMarket, PolymarketOutcome) -> Void
    ) -> Self {
        let ordered = event.markets.orderedForDisplay

        return Self(
            iconURL: event.iconURL ?? event.imageURL,
            title: event.title,
            isLive: event.isLive,
            categoryName: category?.label,
            volumeText: event.volume.map(MappingConstants.volumeFormatter.formatMarketCap),
            activeMarkets: ordered.filter(\.isTradable).map { market in
                makeCard(
                    market: market,
                    event: event,
                    showsOutcomes: market.isAcceptingOrders,
                    onSelectOutcome: onSelectOutcome
                )
            },
            closedMarkets: ordered.filter { !$0.isTradable }.map { market in
                makeCard(market: market, event: event, showsOutcomes: false, onSelectOutcome: onSelectOutcome)
            },
            description: event.description?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
            resolutionDateText: event.endDate.map(MappingConstants.dateFormatter.string),
            marketOpenedDateText: event.startDate.map(MappingConstants.dateFormatter.string)
        )
    }

    private static func makeCard(
        market: PolymarketMarket,
        event: PolymarketEvent,
        showsOutcomes: Bool = true,
        onSelectOutcome: @escaping (PolymarketMarket, PolymarketOutcome) -> Void
    ) -> PolymarketMarketCard.Model {
        .make(
            market: market,
            title: title(for: market, in: event),
            fallbackImageURL: event.iconURL ?? event.imageURL,
            showsOutcomes: showsOutcomes,
            onSelectOutcome: { onSelectOutcome(market, $0) }
        )
    }

    private static func title(for market: PolymarketMarket, in event: PolymarketEvent) -> String {
        switch event.displayMode {
        case .groupedOutcomes: market.groupItemTitle ?? market.title
        case .plainMarkets: market.title
        }
    }
}

// MARK: - Market status

private extension [PolymarketMarket] {
    var orderedForDisplay: [PolymarketMarket] {
        enumerated()
            .sorted { lhs, rhs in
                guard let left = lhs.element.orderIndex, let right = rhs.element.orderIndex, left != right else {
                    return lhs.offset < rhs.offset
                }

                return left < right
            }
            .map(\.element)
    }
}

private extension PolymarketMarket {
    var isTradable: Bool {
        switch status {
        case .active, .unknown: true
        case .closed, .archived: false
        }
    }
}

// MARK: - Constants

private extension PolymarketEventDetailsContent {
    enum MappingConstants {
        static let volumeFormatter = MarketCapFormatter(
            divisorsList: AmountNotationSuffixFormatter.Divisor.defaultList,
            baseCurrencyCode: AppConstants.usdCurrencyCode,
            notationFormatter: DefaultAmountNotationFormatter()
        )

        static let dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(identifier: "America/New_York")
            formatter.dateFormat = "MMM d, yyyy, h:mm a 'ET'"
            return formatter
        }()
    }
}
