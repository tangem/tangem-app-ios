//
//  TokenSummaryView.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import BlockchainSdk
import TangemAssets
import TangemUI
import TangemUIUtils
import TangemLocalization

struct TokenSummaryView: View {
    @ObservedObject var viewModel: TokenSummaryViewModel

    var body: some View {
        VStack(spacing: 0) {
            navigationBar

            ScrollView {
                VStack(spacing: 24) {
                    periodPicker

                    TokenSummaryGaugeView(
                        outlook: viewModel.outlook,
                        lastUpdated: viewModel.lastUpdated
                    )

                    aiSummary

                    metricsSection
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }

            goToSwapButton
        }
        .background {
            DesignSystem.Color.bgSecondary.ignoresSafeArea()
        }
    }

    private var navigationBar: some View {
        HStack(spacing: 12) {
            TokenIcon(tokenIconInfo: viewModel.tokenIconInfo, size: CGSize(bothDimensions: 40))

            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.tokenName)
                    .style(DesignSystem.Font.headingSmallToken, color: DesignSystem.Color.textPrimary)

                Text(viewModel.networkName)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
            }

            Spacer()

            TangemUI.Button(
                icon: DesignSystem.Icons.Cross.regular20,
                accessibilityLabel: Localization.commonClose,
                action: viewModel.closeTapped
            )
            .size(.x11)
            .styleType(.material(.glass))
        }
        .padding(16)
    }

    private var periodPicker: some View {
        TangemSegmentedPicker(
            data: TokenSummaryPeriod.allCases,
            selection: $viewModel.selectedPeriod
        )
        .style(.flexible)
        .showSeparators(false)
    }

    @ViewBuilder
    private var aiSummary: some View {
        if let aiSummaryText = viewModel.aiSummaryText {
            HStack(alignment: .top, spacing: 12) {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                DesignSystem.Color.iconAccentViolet,
                                DesignSystem.Color.iconAccentBlue,
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 2)

                Text(aiSummaryText)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var metricsSection: some View {
        VStack(spacing: 0) {
            ForEach(viewModel.metrics) { metric in
                metricRow(metric)
            }
        }
    }

    private func metricRow(_ metric: TokenSummaryMetric) -> some View {
        HStack(spacing: 8) {
            HStack(spacing: 4) {
                Text(metric.title)
                    .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textPrimary)

                SwiftUI.Button {
                    viewModel.metricInfoTapped(metric)
                } label: {
                    DesignSystem.Icons.Info.regular16.image
                        .renderingMode(.template)
                        .foregroundStyle(DesignSystem.Color.iconSecondary)
                        .frame(width: 16, height: 16)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(metric.title)
            }

            Spacer()

            HStack(spacing: 2) {
                Badge(label: metric.value, accessibilityLabel: nil)
                    .size(.x6)
                    .variant(.tinted)
                    .appearance(.neutral)

                Badge(label: metric.sentiment.badgeTitle, accessibilityLabel: nil)
                    .size(.x6)
                    .variant(.tinted)
                    .appearance(metric.sentiment.badgeAppearance)
            }
        }
        .frame(height: 48)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(DesignSystem.Color.borderSecondary)
                .frame(height: 1)
        }
    }

    private var goToSwapButton: some View {
        TangemUI.Button(
            label: AttributedString(Localization.tokenSummaryGoToSwapButton),
            accessibilityLabel: Localization.tokenSummaryGoToSwapButton,
            action: viewModel.goToSwapTapped
        )
        .styleType(.default)
        .size(.x12)
        .horizontalLayout(.infinity)
        .padding(16)
    }
}

// MARK: - TokenSummaryOutlook + badge appearance

private extension TokenSummaryOutlook {
    var badgeTitle: String {
        switch self {
        case .positive: Localization.commonPositive
        case .neutral: Localization.commonNeutral
        case .negative: Localization.commonNegative
        }
    }

    var badgeAppearance: BadgeAppearance {
        switch self {
        case .positive: .success
        case .neutral: .info
        case .negative: .error
        }
    }
}

// MARK: - Previews

#Preview {
    TokenSummaryView(viewModel: .mock(tokenItem: .blockchain(BlockchainNetwork(.bitcoin(testnet: false), derivationPath: nil))))
}
