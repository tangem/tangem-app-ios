//
//  MarketTokenRowView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemAccessibilityIdentifiers

struct MarketTokenRowView: View {
    @ObservedObject var viewModel: MarketTokenItemViewModel

    @ScaledSize private var iconSize: CGSize = .init(bothDimensions: 40)
    @ScaledSize private var chartSize: CGSize = .init(width: 56, height: 24)
    @ScaledMetric private var horizontalPadding: CGFloat = SizeUnit.x4.value
    @ScaledMetric private var verticalPadding: CGFloat = SizeUnit.x3.value
    @ScaledMetric private var chartSpacing: CGFloat = SizeUnit.x2.value
    @ScaledSize private var oliveSize: CGSize = .init(width: 12, height: 16)

    var body: some View {
        Button(action: { viewModel.didTapAction?() }) {
            HStack(spacing: chartSpacing) {
                TangemTwoLineRowLayout(
                    icon: { iconView },
                    primaryLeading: { nameAndSymbolView },
                    primaryTrailing: { priceView },
                    secondaryLeading: { marketInfoView },
                    secondaryTrailing: { priceChangeView }
                )

                chartView
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(
            MarketsAccessibilityIdentifiers.marketsListTokenItem(uniqueId: viewModel.name)
        )
    }

    // MARK: - Subviews

    private var iconView: some View {
        IconView(url: viewModel.imageURL, size: iconSize, forceKingfisher: true)
            .accessibilityIdentifier(MarketsAccessibilityIdentifiers.marketsListTokenIcon)
    }

    private var nameAndSymbolView: some View {
        HStack(alignment: .firstTextBaseline, spacing: SizeUnit.x1.value) {
            Text(viewModel.name)
                .lineLimit(1)
                .truncationMode(.middle)
                .style(TangemRowConstants.Style.Title.font, color: TangemRowConstants.Style.Title.color)
                .accessibilityIdentifier(MarketsAccessibilityIdentifiers.marketsListTokenNameLabel)

            Text(viewModel.symbol)
                .lineLimit(1)
                .style(TangemRowConstants.Style.Subtitle.font, color: TangemRowConstants.Style.Subtitle.color)
                .accessibilityIdentifier(MarketsAccessibilityIdentifiers.marketsListTokenCurrencyLabel)
        }
    }

    private var priceView: some View {
        Text(viewModel.priceValue)
            .lineLimit(1)
            .blinkForegroundColor(
                publisher: viewModel.$priceChangeAnimation,
                positiveColor: .Tangem.Text.Status.accent,
                negativeColor: .Tangem.Text.Status.warning,
                originalColor: .Tangem.Text.Neutral.primary
            )
            .style(.Tangem.Caption13.regular, color: .Tangem.Text.Neutral.primary)
            .accessibilityIdentifier(MarketsAccessibilityIdentifiers.marketsListTokenPrice)
    }

    private var marketInfoView: some View {
        let rank = viewModel.marketRating.flatMap(Int.init)
        let marketCapColor = rankColors(for: rank).textColor

        return HStack(spacing: SizeUnit.x1.value) {
            if let marketRating = viewModel.marketRating, let rank {
                rankBadgeView(rating: marketRating, rank: rank)
                    .fixedSize()
                    .accessibilityIdentifier(MarketsAccessibilityIdentifiers.marketsListTokenRating)
            }

            Text(viewModel.marketCap)
                .lineLimit(1)
                .style(.Tangem.Caption12.semibold, color: marketCapColor)
                .accessibilityIdentifier(MarketsAccessibilityIdentifiers.marketsListTokenMarketCap)

            if let maxApy = viewModel.maxApy {
                TangemBadge(text: maxApy, size: .x4)
                    .type(.tinted)
                    .color(.gray)
            }
        }
    }

    private var priceChangeView: some View {
        PriceChangeView(state: viewModel.priceChangeState, useRedesignColors: true)
            .accessibilityIdentifier(MarketsAccessibilityIdentifiers.marketsListTokenPriceChange)
    }

    @ViewBuilder
    private var chartView: some View {
        Group {
            if let charts = viewModel.charts {
                LineChartView(
                    color: viewModel.priceChangeState.changeType?.color ?? .Tangem.Text.Neutral.tertiary,
                    data: charts
                )
            } else {
                Color.clear
                    .skeletonable(
                        isShown: true,
                        size: CGSize(width: chartSize.width, height: SizeUnit.x3.value),
                        radius: SizeUnit.x1.value
                    )
            }
        }
        .frame(size: chartSize, alignment: .center)
        .accessibilityIdentifier(MarketsAccessibilityIdentifiers.marketsListTokenChart)
    }

    // MARK: - Rank Badge

    private func rankBadgeView(rating: String, rank: Int) -> some View {
        let colors = rankColors(for: rank)

        return HStack(alignment: .center, spacing: .zero) {
            Assets.DesignSystem.oliveLeft.image
                .resizable()
                .renderingMode(.template)
                .frame(size: oliveSize)
                .foregroundStyle(colors.oliveColor)

            Text(rating)
                .style(.Tangem.Caption12.semibold, color: colors.textColor)

            Assets.DesignSystem.oliveRight.image
                .resizable()
                .renderingMode(.template)
                .frame(size: oliveSize)
                .foregroundStyle(colors.oliveColor)
        }
    }

    private func rankColors(for rank: Int?) -> (oliveColor: Color, textColor: Color) {
        switch rank {
        case 1: (oliveColor: .Tangem.Market.iconTop1, textColor: .Tangem.Market.textTop1)
        case 2: (oliveColor: .Tangem.Market.iconTop2, textColor: .Tangem.Market.textTop2)
        case 3: (oliveColor: .Tangem.Market.iconTop3, textColor: .Tangem.Market.textTop3)
        default: (oliveColor: .Tangem.Graphic.Neutral.secondary, textColor: .Tangem.Text.Neutral.secondary)
        }
    }
}

// MARK: - Previews

#if DEBUG

private let previewTokens: [MarketsTokenModel] = [
    MarketsTokenModel(
        id: "bitcoin",
        name: "Bitcoin",
        symbol: "BTC",
        currentPrice: 67432.12,
        priceChangePercentage: ["24h": 2.35],
        marketRating: 1,
        maxYieldApy: nil,
        marketCap: 1_320_000_000_000,
        isUnderMarketCapLimit: false,
        stakingOpportunities: nil,
        networks: nil
    ),
    MarketsTokenModel(
        id: "ethereum",
        name: "Ethereum",
        symbol: "ETH",
        currentPrice: 3521.87,
        priceChangePercentage: ["24h": -1.12],
        marketRating: 2,
        maxYieldApy: 0.042,
        marketCap: 423_000_000_000,
        isUnderMarketCapLimit: false,
        stakingOpportunities: nil,
        networks: nil
    ),
    MarketsTokenModel(
        id: "solana",
        name: "Solana",
        symbol: "SOL",
        currentPrice: 142.55,
        priceChangePercentage: ["24h": 5.67],
        marketRating: 5,
        maxYieldApy: nil,
        marketCap: 62_000_000_000,
        isUnderMarketCapLimit: false,
        stakingOpportunities: nil,
        networks: nil
    ),
]

private func previewViewModel(for token: MarketsTokenModel) -> MarketTokenItemViewModel {
    MarketTokenItemViewModel(
        tokenModel: token,
        marketCapFormatter: MarketCapFormatter(
            divisorsList: AmountNotationSuffixFormatter.Divisor.defaultList,
            baseCurrencyCode: "USD",
            notationFormatter: DefaultAmountNotationFormatter()
        ),
        chartsProvider: MarketsListChartsHistoryProvider(),
        filterProvider: MarketsListDataFilterProvider(),
        onTapAction: nil
    )
}

#Preview {
    ScrollView(.vertical) {
        ForEach(previewTokens.indexed(), id: \.1.id) { _, token in
            MarketTokenRowView(viewModel: previewViewModel(for: token))
        }
    }
}

#Preview("Dynamic Type - Accessibility1") {
    ScrollView(.vertical) {
        ForEach(previewTokens.indexed(), id: \.1.id) { _, token in
            MarketTokenRowView(viewModel: previewViewModel(for: token))
        }
    }
    .environment(\.dynamicTypeSize, .accessibility1)
}

#endif // DEBUG
