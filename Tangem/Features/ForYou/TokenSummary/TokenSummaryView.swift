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

    @ScaledMetric private var iconSize: CGFloat = 40

    var body: some View {
        VStack(spacing: 0) {
            navigationBar

            ScrollView {
                VStack(spacing: 24) {
                    if viewModel.isPeriodPickerVisible {
                        periodPicker
                    }

                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.top, 64)
                    } else {
                        TokenSummaryGaugeView(
                            state: viewModel.gaugeState,
                            lastUpdated: viewModel.lastUpdated
                        )

                        aiSummary

                        metricsSection
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }

            primaryActionButton
        }
        .background {
            DesignSystem.Color.bgSecondary.ignoresSafeArea()
        }
    }

    private var navigationBar: some View {
        HStack(spacing: 12) {
            TokenIcon(tokenIconInfo: viewModel.tokenIconInfo, size: CGSize(bothDimensions: iconSize))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.tokenName)
                    .style(DesignSystem.Font.headingSmallToken, color: DesignSystem.Color.textPrimary)

                if let networkName = viewModel.networkName {
                    Text(networkName)
                        .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                }
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
                switch metric.content {
                case .reading(let value, let sentiment):
                    Badge(label: value, accessibilityLabel: nil)
                        .size(.x6)
                        .variant(.tinted)
                        .appearance(.neutral)

                    Badge(label: sentiment.badgeTitle, accessibilityLabel: nil)
                        .size(.x6)
                        .variant(.tinted)
                        .appearance(sentiment.badgeAppearance)

                case .unavailable:
                    Badge(label: Localization.commonNone, accessibilityLabel: nil)
                        .size(.x6)
                        .variant(.tinted)
                        .appearance(.neutral)
                }
            }
        }
        .frame(height: 48)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(DesignSystem.Color.borderSecondary)
                .frame(height: 1)
        }
    }

    @ViewBuilder
    private var primaryActionButton: some View {
        if let primaryAction = viewModel.primaryAction {
            TangemUI.Button(
                label: primaryAction.title,
                accessibilityLabel: primaryAction.title,
                action: viewModel.primaryActionTapped
            )
            .styleType(.default)
            .size(.x12)
            .horizontalLayout(.infinity)
            .disabled(!primaryAction.isEnabled)
            .padding(16)
        }
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
