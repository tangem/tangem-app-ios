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
    @ScaledMetric private var trackContainerHeight: CGFloat = Constants.trackContainerHeight

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 0) {
                // [REDACTED_TODO_COMMENT]
                Text("Total market cap")
                    .style(DesignSystem.Font.headingSmallToken, color: DesignSystem.Color.textSecondary)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(viewModel.totalMarketCap)
                        .style(DesignSystem.Font.headingSmallToken, color: DesignSystem.Color.textPrimary)

                    UtilPriceChange(value: viewModel.totalMarketCapChange, direction: .positive)
                }
            }

            HStack(spacing: 11) {
                ForEach(viewModel.metrics) { metric($0) }
            }
        }
        .padding(.horizontal, 16)
    }

    private func metric(_ metric: MarketCapViewModel.Metric) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 0) {
                Text(metric.title)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)

                Text(metric.status)
                    .style(DesignSystem.Font.captionMediumToken, color: color(for: metric.appearance))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(metric.value)
                    .style(Font.Tangem.Heading22.semibold, color: DesignSystem.Color.textPrimary)

                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    stops: Constants.gradientStops,
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(height: trackHeight)

                        Circle()
                            .fill(DesignSystem.Color.iconPrimary)
                            .frame(size: CGSize(bothDimensions: indicatorSide))
                            .shadow(color: .black.opacity(0.25), radius: 2)
                            .offset(x: (proxy.size.width - indicatorSide) * min(max(metric.progress, 0), 1))
                    }
                    .frame(height: trackContainerHeight)
                }
                .frame(height: trackContainerHeight)
            }
        }
        .padding(Constants.cardPadding)
        .frame(maxWidth: .infinity, minHeight: Constants.cardMinHeight, alignment: .leading)
        .background(DesignSystem.Color.bgSecondary, in: RoundedRectangle(cornerRadius: Constants.cardCornerRadius, style: .circular))
    }

    private func color(for appearance: MarketCapViewModel.Metric.Appearance) -> Color {
        switch appearance {
        case .negative: DesignSystem.Color.textStatusError
        case .positive: DesignSystem.Color.textAccentGreen
        }
    }
}

// MARK: - Constants

private extension MarketCapView {
    enum Constants {
        static let indicatorSide: CGFloat = 8
        static let trackHeight: CGFloat = 4
        static let trackContainerHeight: CGFloat = 12
        static let cardPadding: CGFloat = 16
        static let cardMinHeight: CGFloat = 118
        static let cardCornerRadius: CGFloat = 24
        static let gradientStops: [Gradient.Stop] = [
            .init(color: DesignSystem.Color.paletteRed50, location: 0),
            .init(color: DesignSystem.Color.paletteRed50, location: 0.207912),
            .init(color: DesignSystem.Color.paletteYellow50, location: 0.406773),
            .init(color: DesignSystem.Color.paletteGreen50, location: 0.656092),
            .init(color: DesignSystem.Color.paletteBlue50, location: 1),
        ]
    }
}
