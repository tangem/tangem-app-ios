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
        abbreviatesHugeVolumeChange: Bool = false,
        onSelectOutcome: @escaping (PolymarketMarket, PolymarketOutcome) -> Void
    ) -> Self {
        let ordered = event.markets.orderedForDisplay
        let shown = ordered.filter { $0.displaySection != .hidden }
        let visible = shown.isEmpty ? ordered : shown

        return Self(
            iconURL: event.iconURL ?? event.imageURL,
            title: event.title,
            isLive: event.isLive,
            categoryName: category?.label,
            volumeText: event.volume.map(MappingConstants.volumeFormatter.formatMarketCap),
            volumeChange: volumeChange(event: event, abbreviatesHugeChange: abbreviatesHugeVolumeChange),
            activeMarkets: visible.filter { $0.displaySection == .active }.map { market in
                makeCard(
                    market: market,
                    event: event,
                    areOutcomesEnabled: market.isAcceptingOrders,
                    onSelectOutcome: onSelectOutcome
                )
            },
            closedMarkets: visible.filter { $0.displaySection != .active }.map { market in
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
            title: event.listLabel(for: market),
            fallbackImageURL: event.iconURL ?? event.imageURL,
            areOutcomesEnabled: areOutcomesEnabled,
            outcomeTitles: event.buttonTitles(for: market),
            onSelectOutcome: { onSelectOutcome(market, $0) }
        )
    }

    private static func volumeChange(event: PolymarketEvent, abbreviatesHugeChange: Bool) -> VolumeChange {
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
            text: abbreviatesHugeChange ? compactVolumeChangeText(ratio: ratio) : MappingConstants.percentFormatter.format(ratio, option: .priceChange),
            type: PriceChangeView.ChangeType(from: ratio)
        )
    }

    private static func compactVolumeChangeText(ratio: Decimal) -> String {
        let percent = ratio * MappingConstants.percentMultiplier

        guard abs(percent) >= MappingConstants.compactPercentThreshold else {
            return MappingConstants.percentFormatter.format(ratio, option: .priceChange)
        }

        let notation = MappingConstants.percentNotationFormatter.formatWithNotation(percent)
        let number = MappingConstants.compactPercentNumberFormatter.string(from: notation.decimal as NSDecimalNumber)
            ?? "\(notation.decimal)"

        return number + notation.suffix + PercentFormatter.Suffix.default.value
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

private enum MarketDisplaySection {
    case active
    case closed
    case hidden
}

private extension PolymarketMarket {
    var displaySection: MarketDisplaySection {
        switch status {
        case .active, .unknown: .active
        case .closed: .closed
        case .archived: .hidden
        }
    }
}

// MARK: - Constants

private extension PolymarketEventDetailsContent {
    enum MappingConstants {
        static let percentFormatter = PercentFormatter()
        static let percentMultiplier: Decimal = 100
        static let compactPercentThreshold: Decimal = 1000
        static let percentNotationFormatter = AmountNotationSuffixFormatter()
        static let compactPercentNumberFormatter: NumberFormatter = {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.locale = .current
            formatter.minimumFractionDigits = 0
            formatter.maximumFractionDigits = 2
            return formatter
        }()

        static let volumeFormatter = MarketCapFormatter(
            divisorsList: AmountNotationSuffixFormatter.Divisor.defaultList,
            baseCurrencyCode: AppConstants.usdCurrencyCode,
            notationFormatter: DefaultAmountNotationFormatter()
        )

        static let dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.timeZone = TimeZone(identifier: "America/New_York")
            formatter.setLocalizedDateFormatFromTemplate(dateTemplate)
            formatter.dateFormat = (formatter.dateFormat ?? dateTemplate).appending(marketTimeZoneSuffix)
            return formatter
        }()

        static let dateTemplate = "MMMdyyyyjmm"
        static let marketTimeZoneSuffix = " 'ET'"
    }
}
