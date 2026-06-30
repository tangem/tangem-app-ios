//
//  MetricsCards.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI

// MARK: - Market Cap Card

struct MetricsMarketCapCard: View {
    let viewModel: MarketsTokenDetailsMetricsViewModel

    var body: some View {
        MetricsCardContainer(backgroundColor: .Tangem.Surface.level3, action: action) {
            VStack(alignment: .leading, spacing: .zero) {
                MetricsValueText(viewModel.record(for: .marketCapitalization)?.recordData)

                Spacer()

                MetricsInfoLabel(
                    title: Localization.marketsTokenDetailsMarketCapitalization,
                    action: action
                )
            }
        }
    }

    private func action() {
        viewModel.showInfoBottomSheet(for: MarketsTokenDetailsMetricsView.RecordType.marketCapitalization)
    }
}

// MARK: - Trading Volume Card

struct MetricsTradingVolumeCard: View {
    let viewModel: MarketsTokenDetailsMetricsViewModel

    private var state: MarketsTokenDetailsMetricsViewModel.TradingVolumeState {
        viewModel.redesign.tradingVolume
    }

    private var color: Color {
        switch state.liquidityLevel {
        case .high: .Tangem.Text.Status.positive
        case .medium: .Tangem.Text.Status.attention
        case .low: .Tangem.Text.Status.warning
        case .unknown: .Tangem.Text.Neutral.tertiary
        }
    }

    var body: some View {
        MetricsCardContainer(backgroundColor: .Tangem.Surface.level3, action: action) {
            VStack(alignment: .leading, spacing: .zero) {
                titleRow

                Spacer()

                bottomSection
            }
        }
    }

    private var titleRow: some View {
        HStack(alignment: .top, spacing: .zero) {
            MetricsValueText(viewModel.record(for: .tradingVolume)?.recordData)

            Text(Localization.marketsTokenDetailsTradingInterval)
                .style(
                    Font.Tangem.Caption11.medium,
                    color: MetricsValueText.color(
                        hasData: viewModel.record(for: .tradingVolume) != nil
                    )
                )
                .padding(.leading, .unit(.x1))
                .padding(.top, .unit(.x1))
        }
    }

    private var bottomSection: some View {
        VStack(alignment: .leading, spacing: .unit(.x2)) {
            if let liquidity = state.liquidity {
                MetricsProgressBar(
                    progress: liquidity,
                    foregroundColor: color,
                    backgroundColor: Color.Tangem.Fill.Neutral.primary.opacity(0.1)
                )
            }

            MetricsInfoLabel(
                title: Localization.marketsTokenDetailsTradingVolume,
                action: action
            )
        }
    }

    private func action() {
        viewModel.showInfoBottomSheet(for: MarketsTokenDetailsMetricsView.RecordType.tradingVolume)
    }
}

// MARK: - FDV Card

struct MetricsFDVCard: View {
    let viewModel: MarketsTokenDetailsMetricsViewModel

    var body: some View {
        MetricsCardContainer(backgroundColor: .Tangem.Surface.level3, action: action) {
            VStack(alignment: .leading, spacing: .zero) {
                VStack(alignment: .leading, spacing: .unit(.x1)) {
                    titleRow

                    if let recordSubdata = viewModel.record(for: .fullyDilutedValuation)?.recordSubdata {
                        Text(Localization.marketsTokenDetailsValuationValueInTotal(recordSubdata))
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                            .style(Font.Tangem.Caption12.medium, color: .Tangem.Text.Neutral.primary)
                    }
                }

                Spacer()

                MetricsInfoLabel(
                    title: Localization.marketsTokenDetailsFullyDilutedValuation,
                    action: action
                )
            }
        }
    }

    private var titleRow: some View {
        HStack(alignment: .top, spacing: .zero) {
            MetricsValueText(viewModel.record(for: .fullyDilutedValuation)?.recordData)

            Text(Localization.marketsTokenDetailsTradingInterval)
                .style(
                    Font.Tangem.Caption11.medium,
                    color: MetricsValueText.color(
                        hasData: viewModel.record(for: .fullyDilutedValuation) != nil
                    )
                )
                .padding(.leading, .unit(.x1))
                .padding(.top, .unit(.x1))
        }
    }

    private func action() {
        viewModel.showInfoBottomSheet(for: MarketsTokenDetailsMetricsView.RecordType.fullyDilutedValuation)
    }
}

// MARK: - Circulating Supply Card

struct MetricsCirculatingSupplyCard: View {
    let viewModel: MarketsTokenDetailsMetricsViewModel

    private var redesign: MarketsTokenDetailsMetricsViewModel.RedesignState {
        viewModel.redesign
    }

    var body: some View {
        VStack(spacing: .unit(.x5)) {
            HStack(alignment: .top) {
                circulatingColumn

                Spacer()

                maxSupplyColumn
            }

            progressBar
        }
        .roundedBackground(
            with: .Tangem.Surface.level3,
            padding: .unit(.x4),
            radius: .unit(.x6)
        )
        .onTapGesture {
            viewModel.showInfoBottomSheet(for: MarketsTokenDetailsMetricsView.RecordType.circulatingSupply)
        }
    }

    private var circulatingColumn: some View {
        VStack(alignment: .leading, spacing: .unit(.x3)) {
            Text(Localization.marketsTokenDetailsCirculatingSupply)
                .style(Font.Tangem.Caption12.semibold, color: .Tangem.Text.Neutral.tertiary)

            HStack(alignment: .firstTextBaseline, spacing: .unit(.x1)) {
                MetricsValueText(redesign.formattedCirculatingSupply)

                Text(redesign.cryptoCurrencyCode)
                    .lineLimit(1)
                    .style(Font.Tangem.Heading20.semibold, color: .Tangem.Text.Neutral.secondary)
            }
        }
    }

    private var maxSupplyColumn: some View {
        VStack(alignment: .trailing, spacing: .unit(.x3)) {
            Text(Localization.marketsTokenDetailsMaxSupply)
                .style(Font.Tangem.Caption12.semibold, color: .Tangem.Text.Neutral.tertiary)

            MetricsValueText(redesign.formattedMaxSupply)
        }
    }

    @ViewBuilder
    private var progressBar: some View {
        if let supplyProgress = redesign.circulatingSupplyProgress {
            MetricsProgressBar(
                progress: supplyProgress,
                foregroundColor: .Tangem.Text.Status.accent,
                backgroundColor: Color.Tangem.Fill.Neutral.primary.opacity(0.1)
            )
        }
    }
}

// MARK: - MetricsValueText

struct MetricsValueText: View {
    let value: String?

    init(_ value: String?) {
        self.value = value
    }

    var body: some View {
        Text(value ?? Localization.tokenMarketMetricsNoData)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .style(Font.Tangem.Heading20.semibold, color: Self.color(hasData: value != nil))
    }

    static func color(hasData: Bool) -> Color {
        hasData ? .Tangem.Text.Neutral.primary : .Tangem.Text.Neutral.tertiary
    }
}

// MARK: - MetricsInfoLabel

struct MetricsInfoLabel: View {
    let title: String
    var color: Color = .Tangem.Text.Neutral.secondary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: .unit(.x1)) {
                Assets.infoCircle16.image
                    .renderingMode(.template)
                    .foregroundStyle(color)

                Text(title)
                    .lineLimit(1)
                    .style(Font.Tangem.Caption12.semibold, color: color)
            }
        }
        .buttonStyle(.plain)
    }
}
