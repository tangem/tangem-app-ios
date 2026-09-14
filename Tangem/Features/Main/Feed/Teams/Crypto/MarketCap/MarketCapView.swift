//
//  MarketCapView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI

struct MarketCapView: View {
    @ObservedObject var viewModel: MarketCapViewModel

    @ScaledMetric private var indicatorSide: CGFloat = Constants.indicatorSide
    @ScaledMetric private var trackHeight: CGFloat = Constants.trackHeight

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(Localization.marketsTokenDetailsMarketCapitalizationFull)
                    .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)

                Text(viewModel.totalMarketCap)
                    .style(DesignSystem.Font.headingMediumToken, color: DesignSystem.Color.textPrimary)
            }

            HStack(spacing: 8) {
                ForEach(viewModel.metrics) { metric($0) }
            }
        }
        .padding(.horizontal, 16)
    }

    private func metric(_ metric: MarketCapViewModel.Metric) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(metric.title)
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textTertiary)

            Text(metric.status)
                .style(DesignSystem.Font.captionMediumToken, color: color(for: metric.appearance))
                .padding(.top, 2)

            Text(metric.value)
                .style(DesignSystem.Font.headingMediumToken, color: DesignSystem.Color.textPrimary)
                .padding(.top, 4)

            Spacer(minLength: 0)

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    DesignSystem.Color.iconAccentRed,
                                    DesignSystem.Color.iconAccentOrange,
                                    DesignSystem.Color.iconAccentYellow,
                                    DesignSystem.Color.iconAccentGreen,
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: trackHeight)

                    Circle()
                        .fill(DesignSystem.Color.iconPrimary)
                        .frame(size: CGSize(bothDimensions: indicatorSide))
                        .offset(x: proxy.size.width * metric.progress - indicatorSide / 2)
                }
            }
            .frame(height: indicatorSide)
            .padding(.top, Constants.trackTopInset)
        }
        .padding(Constants.cardPadding)
        .frame(maxWidth: .infinity, minHeight: Constants.cardMinHeight, alignment: .leading)
        .background(DesignSystem.Color.bgSecondary, in: RoundedRectangle(cornerRadius: Constants.cardCornerRadius, style: .continuous))
    }

    private func color(for appearance: MarketCapViewModel.Metric.Appearance) -> Color {
        switch appearance {
        case .warning: DesignSystem.Color.textAccentOrange
        case .positive: DesignSystem.Color.textAccentGreen
        }
    }
}

// MARK: - Constants

private extension MarketCapView {
    enum Constants {
        static let indicatorSide: CGFloat = 10
        static let trackHeight: CGFloat = 4
        static let trackTopInset: CGFloat = 4
        static let cardPadding: CGFloat = 12
        static let cardMinHeight: CGFloat = 110
        static let cardCornerRadius: CGFloat = 16
    }
}
