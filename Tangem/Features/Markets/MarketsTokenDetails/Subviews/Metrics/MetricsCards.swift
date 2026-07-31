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
import TangemUIUtils

// MARK: - Market Cap Card

struct MetricsMarketCapCard: View {
    let viewModel: MarketsTokenDetailsMetricsViewModel

    var body: some View {
        MetricsCardContainer(backgroundColor: DesignSystem.Color.bgSecondary, action: action) {
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
        viewModel.showInfoBottomSheet(for: MarketsTokenDetailsMetricsRecordType.marketCapitalization)
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
        case .high: DesignSystem.Color.iconAccentGreen
        case .medium: DesignSystem.Color.iconAccentYellow
        case .low: DesignSystem.Color.iconAccentRed
        case .unknown: DesignSystem.Color.iconAccentNeutral
        }
    }

    var body: some View {
        MetricsCardContainer(backgroundColor: DesignSystem.Color.bgSecondary, action: action) {
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
                    DesignSystem.Font.captionMediumToken,
                    color: MetricsValueText.color(
                        hasData: viewModel.record(for: .tradingVolume) != nil
                    )
                )
                .padding(.leading, 4)
                .padding(.top, 4)
        }
    }

    private var bottomSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let liquidity = state.liquidity {
                MetricsProgressBar(
                    progress: liquidity,
                    foregroundColor: color,
                    backgroundColor: DesignSystem.Color.bgOpaqueSecondary
                )
            }

            MetricsInfoLabel(
                title: Localization.marketsTokenDetailsTradingVolume,
                action: action
            )
        }
    }

    private func action() {
        viewModel.showInfoBottomSheet(for: MarketsTokenDetailsMetricsRecordType.tradingVolume)
    }
}

// MARK: - FDV Card

struct MetricsFDVCard: View {
    let viewModel: MarketsTokenDetailsMetricsViewModel

    var body: some View {
        MetricsCardContainer(backgroundColor: DesignSystem.Color.bgSecondary, action: action) {
            VStack(alignment: .leading, spacing: .zero) {
                VStack(alignment: .leading, spacing: 4) {
                    titleRow

                    if let recordSubdata = viewModel.record(for: .fullyDilutedValuation)?.recordSubdata {
                        Text(Localization.marketsTokenDetailsValuationValueInTotal(recordSubdata))
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                            .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textPrimary)
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
                    DesignSystem.Font.captionMediumToken,
                    color: MetricsValueText.color(
                        hasData: viewModel.record(for: .fullyDilutedValuation) != nil
                    )
                )
                .padding(.leading, 4)
                .padding(.top, 4)
        }
    }

    private func action() {
        viewModel.showInfoBottomSheet(for: MarketsTokenDetailsMetricsRecordType.fullyDilutedValuation)
    }
}

// MARK: - Circulating Supply Card

struct MetricsCirculatingSupplyCard: View {
    let viewModel: MarketsTokenDetailsMetricsViewModel

    private var redesign: MarketsTokenDetailsMetricsViewModel.RedesignState {
        viewModel.redesign
    }

    var body: some View {
        VStack(spacing: 20) {
            HStack(alignment: .top) {
                circulatingColumn

                Spacer()

                maxSupplyColumn
            }

            progressBar
        }
        .roundedBackground(
            with: DesignSystem.Color.bgSecondary,
            padding: 16,
            radius: 24
        )
        .onTapGesture {
            viewModel.showInfoBottomSheet(for: MarketsTokenDetailsMetricsRecordType.circulatingSupply)
        }
    }

    private var circulatingColumn: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Localization.marketsTokenDetailsCirculatingSupply)
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                MetricsValueText(redesign.formattedCirculatingSupply)

                Text(redesign.cryptoCurrencyCode)
                    .lineLimit(1)
                    .style(DesignSystem.Font.headingSmallToken, color: DesignSystem.Color.textSecondary)
            }
        }
    }

    private var maxSupplyColumn: some View {
        VStack(alignment: .trailing, spacing: 12) {
            Text(Localization.marketsTokenDetailsMaxSupply)
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)

            MetricsValueText(redesign.formattedMaxSupply)
        }
    }

    @ViewBuilder
    private var progressBar: some View {
        if let supplyProgress = redesign.circulatingSupplyProgress {
            MetricsProgressBar(
                progress: supplyProgress,
                foregroundColor: DesignSystem.Color.iconAccentBlue,
                backgroundColor: DesignSystem.Color.bgOpaqueSecondary
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
            .style(DesignSystem.Font.headingSmallToken, color: Self.color(hasData: value != nil))
    }

    static func color(hasData: Bool) -> Color {
        hasData ? DesignSystem.Color.textPrimary : DesignSystem.Color.textSecondary
    }
}

// MARK: - MetricsInfoLabel

struct MetricsInfoLabel: View {
    let title: String
    var color: Color = DesignSystem.Color.textSecondary
    let action: () -> Void

    var body: some View {
        SwiftUI.Button(action: action) {
            HStack(spacing: 4) {
                DesignSystem.Icons.Info.regular16.image
                    .renderingMode(.template)
                    .foregroundStyle(color)

                Text(title)
                    .lineLimit(1)
                    .style(DesignSystem.Font.captionMediumToken, color: color)
            }
        }
        .buttonStyle(.plain)
    }
}
