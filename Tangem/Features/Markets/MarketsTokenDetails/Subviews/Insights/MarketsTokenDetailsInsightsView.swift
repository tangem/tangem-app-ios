//
//  MarketsTokenDetailsInsightsView.swift
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
import TangemUIUtils

struct MarketsTokenDetailsInsightsView: View {
    @ObservedObject var viewModel: MarketsTokenDetailsInsightsViewModel

    @ScaledMetric private var trendImageSide: CGFloat = 12

    private let gridItems = [
        GridItem(.flexible(), alignment: .topLeading),
        GridItem(.flexible(), alignment: .topLeading),
    ]

    var body: some View {
        VStack(spacing: 24) {
            header

            LazyVGrid(columns: gridItems, alignment: .leading, spacing: 16) {
                ForEach(indexed: viewModel.records.indexed()) { _, info in
                    recordView(for: info)
                }
            }
            .drawingGroup()
        }
        .roundedBackground(with: DesignSystem.Color.bgSecondary, padding: 16, radius: 24)
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
        let label = HStack(spacing: 4) {
            headerLabel

            if viewModel.shouldShowHeaderInfoButton {
                infoIcon
            }
        }

        if viewModel.shouldShowHeaderInfoButton {
            SwiftUI.Button(action: viewModel.showInsightsSheetInfo) { label }
        } else {
            label
        }
    }

    private var headerLabel: some View {
        Text(Localization.marketsTokenDetailsInsights)
            .style(DesignSystem.Font.headingSmallToken, color: DesignSystem.Color.textPrimary)
    }

    private var infoIcon: some View {
        DesignSystem.Icons.Info.regular16.image
            .renderingMode(.template)
            .foregroundStyle(DesignSystem.Color.iconSecondary)
    }

    private func recordView(for info: MarketsTokenDetailsInsightsRecordInfo) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            valueRow(for: info)

            labelRow(for: info)
        }
    }

    private func valueRow(for info: MarketsTokenDetailsInsightsRecordInfo) -> some View {
        HStack(spacing: 4) {
            Text(info.recordData)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)

            trendIcon(for: info.trend)
        }
    }

    private func labelRow(for info: MarketsTokenDetailsInsightsRecordInfo) -> some View {
        SwiftUI.Button(action: { viewModel.showInfoBottomSheet(for: info.type) }) {
            HStack(spacing: 4) {
                infoIcon

                Text(info.title)
                    .lineLimit(1)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
            }
        }
    }

    @ViewBuilder
    private func trendIcon(for trend: MarketsTokenDetailsStatisticTrend?) -> some View {
        switch trend {
        case .positive:
            Assets.DesignSystem.upDynamic.image
                .resizable()
                .renderingMode(.template)
                .frame(width: trendImageSide, height: trendImageSide)
                .foregroundStyle(DesignSystem.Color.iconAccentBlue)

        case .negative:
            // We don't have a separate icon for negative trend, so we reuse the positive one with rotation
            // Yeah, ugly, but DS is in progress it will be fixed shortly
            Assets.DesignSystem.upDynamic.image
                .resizable()
                .renderingMode(.template)
                .frame(width: trendImageSide, height: trendImageSide)
                .rotationEffect(.degrees(180))
                .foregroundStyle(DesignSystem.Color.iconAccentRed)

        case .none:
            EmptyView()
        }
    }
}

// MARK: - Previews

#Preview {
    MarketsTokenDetailsInsightsView(viewModel: MarketsTokenDetailsInsightsViewModel(
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
