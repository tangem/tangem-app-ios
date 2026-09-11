//
//  PortfolioReviewMapper+ChartBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

extension PortfolioReviewMapper {
    enum ChartBuilder {
        private static let percentFormatter = PercentFormatter()

        /// Only ranked groups get a colour; the rest collapse into one neutral arc that closes the ring.
        /// `noDataReason` tells a valueless portfolio apart from one that could not load at all.
        static func build(
            topHoldings: [PortfolioReviewAggregator.Group],
            other: [PortfolioReviewAggregator.Group],
            slices: [String: PortfolioReviewSegmentPalette.Slice],
            noDataReason: PortfolioReviewViewModel.ViewState.Chart.NoData
        ) -> PortfolioReviewViewModel.ViewState.Chart {
            let groups = topHoldings + other
            guard !groups.isEmpty else {
                return .noData(noDataReason)
            }

            let total = groups.reduce(Decimal.zero) {
                $0 + $1.amountInFiat
            }

            guard total > 0 else {
                return .noData(noDataReason)
            }

            let topShare = topHoldings.reduce(Decimal.zero) {
                $0 + $1.amountInFiat
            } / total

            return .loaded(
                assets: assets(topHoldings: topHoldings, other: other, slices: slices),
                assetCount: topHoldings.count,
                topHoldingPercent: topHoldingPercent(topShare)
            )
        }
    }
}

// MARK: - Summary

private extension PortfolioReviewMapper.ChartBuilder {
    /// Only a share that rounding lifts to a whole hundred is marked approximate: a plain 100% would claim
    /// the top holding is the entire portfolio. Any smaller share states its own rounded value and needs no mark.
    static func topHoldingPercent(_ share: Decimal) -> String {
        let percent = percentFormatter.format(share, option: .yield)

        guard share < 1, percent == percentFormatter.format(1, option: .yield) else { return percent }

        return "\(AppConstants.tildeSign)\(percent)"
    }
}

// MARK: - Assets

private extension PortfolioReviewMapper.ChartBuilder {
    static func assets(
        topHoldings: [PortfolioReviewAggregator.Group],
        other: [PortfolioReviewAggregator.Group],
        slices: [String: PortfolioReviewSegmentPalette.Slice]
    ) -> [SummaryGaugeAsset] {
        var assets = topHoldings.map {
            SummaryGaugeAsset(id: $0.key, name: $0.symbol, fiatValue: $0.amountInFiat, segmentColor: slices[$0.key]?.arc)
        }

        if !other.isEmpty {
            assets.append(SummaryGaugeAsset(
                id: PortfolioRowBuilder.otherID,
                name: Localization.commonOther,
                fiatValue: other.reduce(Decimal.zero) { $0 + $1.amountInFiat },
                segmentColor: PortfolioReviewSegmentPalette.otherColor
            ))
        }

        return assets
    }
}
