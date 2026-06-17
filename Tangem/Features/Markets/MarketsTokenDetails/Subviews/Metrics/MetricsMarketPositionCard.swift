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

struct MetricsMarketPositionCard: View {
    let viewModel: MarketsTokenDetailsMetricsViewModel

    @ScaledMetric private var trendImageSide = CGFloat.unit(.x3)

    private typealias RankType = MarketsTokenDetailsMetricsViewModel.MarketPositionState.RankType
    private typealias RatingChange = MarketsTokenDetailsMetricsViewModel.MarketPositionState.RatingChange

    var body: some View {
        let state = viewModel.redesign.marketPosition
        let color = rankColor(for: state.rankType)

        MetricsCardContainer(backgroundColor: .Tangem.Surface.level3, action: action) {
            VStack(alignment: .leading, spacing: .zero) {
                HStack(spacing: .unit(.x1_5)) {
                    marketPositionValue(state: state, rankColor: color)

                    ratingChangeIndicator(for: state.ratingChange)
                }

                Spacer()

                VStack(alignment: .leading, spacing: .unit(.x2)) {
                    if let progress = state.progress {
                        MetricsProgressBarWithDot(
                            progress: progress,
                            dotColor: .Tangem.Fill.Neutral.primary,
                            backgroundColor: Color.Tangem.Fill.Neutral.primary.opacity(0.1)
                        )
                    }

                    MetricsInfoLabel(
                        title: Localization.marketsTokenDetailsMarketRating,
                        color: color,
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
                    .style(Font.Tangem.Heading20.semibold, color: rankColor)

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
            HStack(spacing: .unit(.half)) {
                Assets.DesignSystem.upDynamic.image
                    .resizable()
                    .renderingMode(.template)
                    .frame(width: trendImageSide, height: trendImageSide)
                    .foregroundStyle(Color.Tangem.Graphic.Status.positive)

                Text("\(value)")
                    .style(Font.Tangem.Caption12.semibold, color: .Tangem.Text.Status.positive)
            }
        case .down(let value):
            HStack(spacing: .unit(.half)) {
                // We don't have a separate icon for negative trend, so we reuse the positive one with rotation
                // Yeah, ugly, but DS is in progress it will be fixed shortly
                Assets.DesignSystem.upDynamic.image
                    .resizable()
                    .renderingMode(.template)
                    .frame(width: trendImageSide, height: trendImageSide)
                    .rotationEffect(.degrees(180))
                    .foregroundStyle(Color.Tangem.Graphic.Status.warning)

                Text("\(value)")
                    .style(Font.Tangem.Caption12.semibold, color: .Tangem.Text.Status.warning)
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
        case .gold: .Tangem.Market.textTop1
        case .silver: .Tangem.Market.textTop2
        case .bronze: .Tangem.Market.textTop3
        case .other: .Tangem.Text.Neutral.primary
        }
    }
}
