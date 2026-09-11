//
//  PortfolioReviewMapper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
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
                        slices: [:],
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

        // Ranked once, here: the rows' dots and the donut's arcs read the same slices.
        let slices = PortfolioReviewSegmentPalette.slices(forRanked: topHoldings.chartableKeys)
        let chart = ChartBuilder.build(
            topHoldings: topHoldings,
            other: other,
            slices: slices,
            noDataReason: emptyChartReason(for: totalBalance)
        )

        // A dot stands for an arc, so a donut that can't be drawn leaves every row without one.
        var rowSlices: [String: PortfolioReviewSegmentPalette.Slice] = [:]
        if case .loaded = chart {
            rowSlices = slices
        }

        return (
            .content(.init(
                tokenList: rowBuilder.build(
                    topHoldings: topHoldings,
                    other: other,
                    addressless: addressless,
                    slices: rowSlices,
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
