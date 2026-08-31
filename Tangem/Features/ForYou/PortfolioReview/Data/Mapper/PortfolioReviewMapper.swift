//
//  PortfolioReviewMapper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import struct SwiftUI.Color
import TangemUI

/// Turns the selected accounts' stored tokens into the Portfolio Review view state: extract → aggregate → build rows.
struct PortfolioReviewMapper {
    private let rowBuilder = PortfolioRowBuilder()

    func map(
        tokenItems: [TokenItemType],
        totalBalance: TotalBalanceState,
        indicators: [String: [TokenSummaryIndicator]],
        timeframe: TokenSummaryIndicator.Timeframe
    ) -> (state: PortfolioReviewViewModel.ViewState, displayedTokenItems: Set<TokenItem>) {
        let holdings = tokenItems.map(HoldingBuilder.build)
        let (topHoldings, other, addressless) = PortfolioReviewAggregator.aggregate(holdings)
        let groups = topHoldings + other

        guard !isStillResolving(groups: groups, totalBalance: totalBalance) else {
            return (.loading, [])
        }

        // Nothing to rank (no tokens / all zero / nothing derived) → NoData chart, tokens still listed, no skeleton.
        guard !groups.isEmpty else {
            let reason = emptyChartReason(for: totalBalance)
            let emptyGroups = PortfolioReviewAggregator.aggregateEmpty(holdings)
            return (
                .content(.init(
                    // No ranking here, so no row carries a slice.
                    tokenList: rowBuilder.build(
                        topHoldings: emptyGroups,
                        other: [],
                        addressless: [],
                        colors: [:],
                        indicators: indicators,
                        timeframe: timeframe
                    ),
                    periodSegments: ForYouPeriodSegment.all,
                    chart: .noData(reason),
                    showsAddFunds: reason == .noAmount
                )),
                displayedTokenItems(in: emptyGroups)
            )
        }

        // Ranked once, so a row's dot and its arc read the very same colour.
        let colors = PortfolioReviewSegmentPalette.colors(forRanked: topHoldings.chartableKeys)
        let chart = makeChart(topHoldings: topHoldings, other: other, colors: colors, totalBalance: totalBalance)

        // No donut, no dots: an empty set of colours leaves every row, the bucket included, without one.
        var rowColors: [String: Color] = [:]
        if case .loaded = chart {
            rowColors = colors
            rowColors[PortfolioRowBuilder.otherID] = PortfolioReviewSegmentPalette.otherIndicatorColor
        }

        return (
            .content(.init(
                tokenList: rowBuilder.build(
                    topHoldings: topHoldings,
                    other: other,
                    addressless: addressless,
                    colors: rowColors,
                    indicators: indicators,
                    timeframe: timeframe
                ),
                periodSegments: ForYouPeriodSegment.all,
                chart: chart,
                showsAddFunds: false
            )),
            displayedTokenItems(in: groups + addressless)
        )
    }
}

// MARK: - Chart

private extension PortfolioReviewMapper {
    /// Feeds every group to the gauge (only the ranked ones carry a colour, but the full sum is the centre total).
    func makeChart(
        topHoldings: [PortfolioReviewAggregator.Group],
        other: [PortfolioReviewAggregator.Group],
        colors: [String: Color],
        totalBalance: TotalBalanceState
    ) -> PortfolioReviewViewModel.ViewState.Chart {
        let groups = topHoldings + other
        guard !groups.isEmpty else {
            return .noData(.cantLoad)
        }

        // A failed total can't be charted even if some tokens loaded — "can't load", not a donut on a partial sum.
        if case .failed = totalBalance {
            return .noData(.cantLoad)
        }

        let total = groups.reduce(Decimal.zero) {
            $0 + $1.amountInFiat
        }

        guard total > 0 else {
            return .noData(.noAmount)
        }

        let topShare = topHoldings.reduce(Decimal.zero) {
            $0 + $1.amountInFiat
        } / total

        return .loaded(
            assets: groups.map {
                SummaryGaugeAsset(id: $0.key, name: $0.tokenItem.name, fiatValue: $0.amountInFiat, segmentColor: colors[$0.key])
            },
            assetCount: topHoldings.count,
            topHoldingPercent: PercentFormatter().format(topShare, option: .yield)
        )
    }
}

// MARK: - State assembly

private extension PortfolioReviewMapper {
    /// Includes the "Other" bucket, excludes zero-balance holdings — the set the outdated-data banner is scoped to.
    func displayedTokenItems(in groups: [PortfolioReviewAggregator.Group]) -> Set<TokenItem> {
        Set(groups.flatMap(\.holdings).map(\.tokenItem))
    }

    func isStillResolving(groups: [PortfolioReviewAggregator.Group], totalBalance: TotalBalanceState) -> Bool {
        if !groups.isEmpty {
            return groups.allSatisfy { $0.availability == .loading }
        }

        switch totalBalance {
        case .loading:
            return true
        case .empty, .failed, .loaded:
            return false
        }
    }

    /// Empty-state chart reason: a failed total reads as "can't load"; a genuinely empty/zero wallet as "no amount".
    func emptyChartReason(for totalBalance: TotalBalanceState) -> PortfolioReviewViewModel.ViewState.Chart.NoData {
        if case .failed = totalBalance {
            return .cantLoad
        }
        return .noAmount
    }
}
