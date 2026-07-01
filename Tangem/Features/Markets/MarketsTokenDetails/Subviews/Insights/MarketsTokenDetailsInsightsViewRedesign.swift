//
//  MarketsTokenDetailsInsightsViewRedesign.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI

struct MarketsTokenDetailsInsightsViewRedesign: View {
    @ObservedObject var viewModel: MarketsTokenDetailsInsightsViewModel

    @ScaledMetric private var trendImageSide: CGFloat = 12

    private let gridItems = [
        GridItem(.flexible(), alignment: .topLeading),
        GridItem(.flexible(), alignment: .topLeading),
    ]

    var body: some View {
        VStack(spacing: .unit(.x6)) {
            header

            LazyVGrid(columns: gridItems, alignment: .leading, spacing: .unit(.x4)) {
                ForEach(indexed: viewModel.records.indexed()) { _, info in
                    recordView(for: info)
                }
            }
            .drawingGroup()
        }
        .roundedBackground(with: .Tangem.Surface.level3, padding: .unit(.x4), radius: .unit(.x6))
    }

    private var header: some View {
        HStack(spacing: .zero) {
            headerTitle

            Spacer()

            TangemSegmentedPicker(
                data: viewModel.availableIntervals,
                selection: $viewModel.selectedInterval
            )
            .style(.fixed)
        }
    }

    @ViewBuilder
    private var headerTitle: some View {
        let label = HStack(spacing: .unit(.x1)) {
            headerLabel

            if viewModel.shouldShowHeaderInfoButton {
                infoIcon
            }
        }

        if viewModel.shouldShowHeaderInfoButton {
            Button(action: viewModel.showInsightsSheetInfo) { label }
        } else {
            label
        }
    }

    private var headerLabel: some View {
        Text(Localization.marketsTokenDetailsInsights)
            .style(Font.Tangem.Heading20.semibold, color: .Tangem.Text.Neutral.primary)
    }

    private var infoIcon: some View {
        Assets.infoCircle16.image
            .renderingMode(.template)
            .foregroundStyle(Color.Tangem.Graphic.Neutral.tertiaryConstant)
    }

    private func recordView(for info: MarketsTokenDetailsInsightsView.RecordInfo) -> some View {
        VStack(alignment: .leading, spacing: .unit(.x1)) {
            valueRow(for: info)

            labelRow(for: info)
        }
    }

    private func valueRow(for info: MarketsTokenDetailsInsightsView.RecordInfo) -> some View {
        HStack(spacing: .unit(.x1)) {
            Text(info.recordData)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .style(Font.Tangem.Body16.semibold, color: .Tangem.Text.Neutral.primary)

            trendIcon(for: info.trend)
        }
    }

    private func labelRow(for info: MarketsTokenDetailsInsightsView.RecordInfo) -> some View {
        Button(action: { viewModel.showInfoBottomSheet(for: info.type) }) {
            HStack(spacing: .unit(.x1)) {
                infoIcon

                Text(info.title)
                    .lineLimit(1)
                    .style(Font.Tangem.Caption12.semibold, color: .Tangem.Text.Neutral.secondary)
            }
        }
    }

    @ViewBuilder
    private func trendIcon(for trend: MarketsTokenDetailsStatisticsRecordView.Trend?) -> some View {
        switch trend {
        case .positive:
            Assets.DesignSystem.upDynamic.image
                .resizable()
                .renderingMode(.template)
                .frame(width: trendImageSide, height: trendImageSide)
                .foregroundStyle(Color.Tangem.Graphic.Status.accent)

        case .negative:
            // We don't have a separate icon for negative trend, so we reuse the positive one with rotation
            // Yeah, ugly, but DS is in progress it will be fixed shortly
            Assets.DesignSystem.upDynamic.image
                .resizable()
                .renderingMode(.template)
                .frame(width: trendImageSide, height: trendImageSide)
                .rotationEffect(.degrees(180))
                .foregroundStyle(Color.Tangem.Graphic.Status.warning)

        case .none:
            EmptyView()
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview {
    MarketsTokenDetailsInsightsViewRedesign(viewModel: MarketsTokenDetailsInsightsViewModel(
        tokenSymbol: "BTC",
        insights: MarketsTokenDetailsInsights(dto: MarketsDTO.Coins.Insights(
            holdersChange: [
                "24h": 358,
                "1w": 120,
                "1m": -50,
            ],
            liquidityChange: [
                "24h": -446.45,
                "1w": -5714908.849255774,
                "1m": -5714908.849255774,
            ],
            buyPressureChange: [
                "24h": -446.45,
                "1w": -334647.79027640104,
                "1m": -4501466.504872012,
            ],
            experiencedBuyerChange: [
                "24h": 44,
                "1w": 10,
                "1m": -5,
            ],
            networks: nil
        ))!,
        insightsPublisher: CurrentValueSubject<MarketsTokenDetailsInsights?, Never>(nil),
        notationFormatter: DefaultAmountNotationFormatter(),
        infoRouter: nil
    )
    )
}
#endif
