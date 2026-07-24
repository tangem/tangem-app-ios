//
//  MetricsMarketPositionCard.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI
import TangemUIUtils

struct MetricsMarketPositionCard: View {
    let viewModel: MarketsTokenDetailsMetricsViewModel

    @ScaledMetric private var trendImageSide = CGFloat(12)

    private typealias RankType = MarketsTokenDetailsMetricsViewModel.MarketPositionState.RankType
    private typealias RatingChange = MarketsTokenDetailsMetricsViewModel.MarketPositionState.RatingChange

    var body: some View {
        let state = viewModel.redesign.marketPosition
        let color = rankColor(for: state.rankType)

        MetricsCardContainer(backgroundColor: DesignSystem.Color.bgSecondary, action: action) {
            VStack(alignment: .leading, spacing: .zero) {
                HStack(spacing: 6) {
                    marketPositionValue(state: state, rankColor: color)

                    ratingChangeIndicator(for: state.ratingChange)
                }

                Spacer()

                VStack(alignment: .leading, spacing: 8) {
                    if let progress = state.progress {
                        MetricsProgressBarWithDot(
                            progress: progress,
                            dotColor: DesignSystem.Color.iconPrimary,
                            backgroundColor: DesignSystem.Color.bgOpaqueSecondary
                        )
                    }

                    MetricsInfoLabel(
                        title: Localization.marketsTokenDetailsMarketRating,
                        color: DesignSystem.Color.textSecondary,
                        action: action
                    )
                }
            }
        }
    }

    // MARK: - Position Value

    @ViewBuilder
    private func marketPositionValue(state: MarketsTokenDetailsMetricsViewModel.MarketPositionState, rankColor: Color) -> some View {
        if let ratingText = state.ratingText {
            HStack(spacing: .zero) {
                Assets.DesignSystem.oliveLeft.image
                    .renderingMode(.template)
                    .foregroundStyle(rankColor)

                Text(ratingText)
                    .style(DesignSystem.Font.headingSmallToken, color: rankColor)

                Assets.DesignSystem.oliveRight.image
                    .renderingMode(.template)
                    .foregroundStyle(rankColor)
            }
        } else {
            MetricsValueText(nil)
        }
    }

    // MARK: - Rating Change Indicator

    @ViewBuilder
    private func ratingChangeIndicator(for change: RatingChange) -> some View {
        switch change {
        case .up(let value):
            HStack(spacing: 2) {
                Assets.DesignSystem.upDynamic.image
                    .resizable()
                    .renderingMode(.template)
                    .frame(width: trendImageSide, height: trendImageSide)
                    .foregroundStyle(DesignSystem.Color.iconAccentBlue)

                Text("\(value)")
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textAccentBlue)
            }
        case .down(let value):
            HStack(spacing: 2) {
                // We don't have a separate icon for negative trend, so we reuse the positive one with rotation
                // Yeah, ugly, but DS is in progress it will be fixed shortly
                Assets.DesignSystem.upDynamic.image
                    .resizable()
                    .renderingMode(.template)
                    .frame(width: trendImageSide, height: trendImageSide)
                    .rotationEffect(.degrees(180))
                    .foregroundStyle(DesignSystem.Color.iconAccentRed)

                Text("\(value)")
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textAccentRed)
            }
        case .none:
            EmptyView()
        }
    }

    private func action() {
        viewModel.showInfoBottomSheet(for: MarketsTokenDetailsMetricsView.RecordType.marketRating)
    }

    // MARK: - Rank Colors

    private func rankColor(for rankType: RankType) -> Color {
        switch rankType {
        // [REDACTED_TODO_COMMENT]
        case .gold: .Tangem.Market.textTop1
        case .silver: .Tangem.Market.textTop2
        case .bronze: .Tangem.Market.textTop3
        case .other: DesignSystem.Color.textPrimary
        }
    }
}
