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
import TangemUI

struct PolymarketEventDetailsContent {
    let iconURL: URL?
    let title: String
    let isLive: Bool
    let categoryName: String?
    let volumeText: String?
    let volumeChange: VolumeChange
    let activeMarkets: [PolymarketMarketCard.Model]
    let closedMarkets: [PolymarketMarketCard.Model]
    let description: String?
    let resolutionDateText: String?
    let marketOpenedDateText: String?

    var hasMeta: Bool {
        isLive || categoryName != nil || volumeText != nil
    }

    struct VolumeChange {
        let text: String
        let type: PriceChangeView.ChangeType
    }

    var hasInfoRows: Bool {
        resolutionDateText != nil || marketOpenedDateText != nil
    }

    var showsClosedMarketsToggle: Bool {
        activeMarkets.isNotEmpty && closedMarkets.isNotEmpty
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
            volumeChange: volumeChange(event: event),
            activeMarkets: ordered.filter(\.isTradable).map { market in
                makeCard(
                    market: market,
                    event: event,
                    areOutcomesEnabled: market.isAcceptingOrders,
                    onSelectOutcome: onSelectOutcome
                )
            },
            closedMarkets: ordered.filter { !$0.isTradable }.map { market in
                makeCard(market: market, event: event, areOutcomesEnabled: false, onSelectOutcome: onSelectOutcome)
            },
            description: event.description?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
            resolutionDateText: event.endDate.map(MappingConstants.dateFormatter.string),
            marketOpenedDateText: event.startDate.map(MappingConstants.dateFormatter.string)
        )
    }

    private static func makeCard(
        market: PolymarketMarket,
        event: PolymarketEvent,
        areOutcomesEnabled: Bool = true,
        onSelectOutcome: @escaping (PolymarketMarket, PolymarketOutcome) -> Void
    ) -> PolymarketMarketCard.Model {
        .make(
            market: market,
            title: title(for: market, in: event),
            fallbackImageURL: event.iconURL ?? event.imageURL,
            areOutcomesEnabled: areOutcomesEnabled,
            onSelectOutcome: { onSelectOutcome(market, $0) }
        )
    }

    private static func volumeChange(event: PolymarketEvent) -> VolumeChange {
        guard
            let volume = event.volume,
            let volume24h = event.volume24h,
            case let previous = volume - volume24h,
            previous > 0
        else {
            return VolumeChange(text: BalanceFormatter.defaultEmptyBalanceString, type: .neutral)
        }

        let ratio = volume24h / previous

        return VolumeChange(
            text: MappingConstants.percentFormatter.format(ratio, option: .priceChange),
            type: PriceChangeView.ChangeType(from: ratio)
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
        static let percentFormatter = PercentFormatter()
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
