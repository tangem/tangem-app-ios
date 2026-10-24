//
//  TokenDetailsMarketPriceView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils
import TangemAccessibilityIdentifiers

struct TokenDetailsMarketPriceView: View {
    let viewModel: TokenDetailsMarketPriceViewModel

    var body: some View {
        SwiftUI.Button(action: viewModel.action) {
            HStack(spacing: .zero) {
                labels

                Spacer(minLength: .zero)

                HStack(spacing: 16) {
                    miniChart
                    expandButton
                }
            }
            .foregroundStyle(DesignSystem.Color.textPrimary)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(height: 64)
            .frame(maxWidth: .infinity)
            .if(!isLiquidGlassSupported) { view in
                view.background(DesignSystem.Color.bgSecondary)
            }
            .clipShape(.capsule)
            .contentShape(.capsule)
        }
        .modifyView { view in
            if #available(iOS 26.0, *) {
                // [REDACTED_USERNAME], liquid glass + scaling causes flicker glitches. `Glass.interactive(:)` + no scaling has decent visuals.
                view
                    .glassEffect(.regular.interactive(), in: .capsule)
                    .buttonStyle(NoOpButtonStyle())
            } else {
                view.buttonStyle(.scaled(scaleAmount: 0.95, dimmingAmount: 1, animation: .easeInOut))
            }
        }
        .accessibilityIdentifier(TokenAccessibilityIdentifiers.marketPriceBlock)
    }

    private var labels: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(viewModel.title)
                .font(token: DesignSystem.Font.bodyMediumToken)
                .accessibilityIdentifier(TokenAccessibilityIdentifiers.marketPriceTitle)

            HStack(spacing: 4) {
                Text(viewModel.subtitle)
                    .font(token: DesignSystem.Font.captionMediumToken)
                    .accessibilityIdentifier(TokenAccessibilityIdentifiers.marketPricePrice)

                PriceChangeView(
                    state: viewModel.priceChange,
                    showSkeletonWhenLoading: true,
                    showIconForNeutral: true,
                    useRedesignColors: true
                )
                .accessibilityIdentifier(TokenAccessibilityIdentifiers.marketPricePriceChange)
            }
        }
    }

    @ViewBuilder
    private var miniChart: some View {
        switch viewModel.miniChartPoints {
        case .success(let points):
            LineChartView(
                color: viewModel.priceChange.changeType?.color ?? DesignSystem.Color.textSecondary,
                data: points
            )
            .frame(width: 52)
            .accessibilityIdentifier(TokenAccessibilityIdentifiers.marketPriceChart)

        case .loading:
            SkeletonView()
                .frame(width: 64, height: 24)
                .clipShape(.rect(cornerRadius: 8))
        }
    }

    private var expandButton: some View {
        TangemUI.Button(
            icon: Assets.arrowExpand,
            accessibilityLabel: nil,
            action: viewModel.action
        )
        .size(.x10)
        .styleType(.secondary(.default))
    }
}

private struct NoOpButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}
