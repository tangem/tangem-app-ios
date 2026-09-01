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
        static func build(
            topHoldings: [PortfolioReviewAggregator.Group],
            other: [PortfolioReviewAggregator.Group],
            slices: [String: PortfolioReviewSegmentPalette.Slice],
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
                assets: assets(topHoldings: topHoldings, other: other, slices: slices),
                assetCount: topHoldings.count,
                topHoldingPercent: percentFormatter.format(topShare, option: .yield)
            )
        }
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
                segmentColor: PortfolioReviewSegmentPalette.otherArcColor
            ))
        }

        return assets
    }
}
