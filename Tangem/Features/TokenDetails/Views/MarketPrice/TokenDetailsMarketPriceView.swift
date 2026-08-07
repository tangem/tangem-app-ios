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
import TangemAccessibilityIdentifiers

struct TokenDetailsMarketPriceView: View {
    let viewModel: TokenDetailsMarketPriceViewModel

    var body: some View {
        Button(action: viewModel.action) {
            HStack(spacing: .zero) {
                labels

                Spacer(minLength: .zero)

                HStack(spacing: .unit(.x4)) {
                    miniChart
                    expandButton
                }
            }
            .foregroundStyle(Color.Tangem.Text.Neutral.primary)
            .padding(.horizontal, .unit(.x4))
            .padding(.vertical, .unit(.x3))
            .frame(height: .unit(.x16))
            .frame(maxWidth: .infinity)
            .if(!isLiquidGlassSupported) { view in
                view.background(Color.Tangem.Surface.level3)
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
        VStack(alignment: .leading, spacing: .unit(.x1)) {
            Text(viewModel.title)
                .font(Font.Tangem.Body16.medium)
                .accessibilityIdentifier(TokenAccessibilityIdentifiers.marketPriceTitle)

            HStack(spacing: .unit(.x1)) {
                Text(viewModel.subtitle)
                    .font(Font.Tangem.Caption12.semibold)
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
                color: viewModel.priceChange.changeType?.color ?? Color.Tangem.Text.Neutral.tertiary,
                data: points
            )
            .frame(width: .unit(.x13))
            .accessibilityIdentifier(TokenAccessibilityIdentifiers.marketPriceChart)

        case .loading:
            SkeletonView()
                .frame(width: 64, height: 24)
                .clipShape(.rect(cornerRadius: 8))
        }
    }

    private var expandButton: some View {
        TangemButtonV2(
            icon: Assets.arrowExpand,
            accessibilityLabel: nil,
            action: viewModel.action
        )
        .size(.x10)
        .styleType(.secondary)
    }
}

private struct NoOpButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}
