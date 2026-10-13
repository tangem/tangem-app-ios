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
import TangemUIUtils

struct MarketCapView: View {
    @ObservedObject var viewModel: MarketCapViewModel

    @ScaledMetric private var infoIconSide: CGFloat = Constants.infoIconSide

    var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                content(MarketCapViewModel.Content.placeholder, isLoading: true)
            case .empty:
                EmptyView()
            case .content(let content):
                self.content(content, isLoading: false)
            }
        }
        .onAppear(perform: viewModel.onViewAppear)
    }

    private func content(_ content: MarketCapViewModel.Content, isLoading: Bool) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 8) {
                    Text(Localization.marketCryptoTotalMarketCapTitle)
                        .style(DesignSystem.Font.headingSmallToken, color: DesignSystem.Color.textSecondary)

                    if !isLoading {
                        infoButton
                    }
                }

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(content.totalMarketCap)
                        .style(DesignSystem.Font.headingSmallToken, color: DesignSystem.Color.textPrimary)
                        .shimmerPlaceholder(isLoading, variant: .custom(width: Constants.capSkeletonSize.width, height: Constants.capSkeletonSize.height, cornerRadius: Constants.skeletonCornerRadius))

                    priceChange(content.priceChange)
                }
            }

            HStack(spacing: 11) {
                ForEach(content.metrics) { metric($0, isLoading: isLoading) }
            }
        }
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private func priceChange(_ state: PriceChangeView.State) -> some View {
        let direction: UtilPriceChange.Direction = switch state.changeType {
        case .positive: .positive
        case .negative: .negative
        case .neutral, nil: .neutral
        }

        switch state {
        case .loaded(_, let text):
            UtilPriceChange(value: text, direction: direction)
                .typography(DesignSystem.Font.headingSmallToken)
        case .loadingCached(_, let text):
            UtilPriceChange(value: text, direction: direction)
                .typography(DesignSystem.Font.headingSmallToken)
                .updating()
        default:
            PriceChangeView(state: state, useRedesignColors: true)
        }
    }

    private var infoButton: some View {
        SwiftUI.Button(action: viewModel.onInfoTap) {
            DesignSystem.Icons.Info.regular16.image
                .renderingMode(.template)
                .foregroundStyle(DesignSystem.Color.iconSecondary)
                .frame(size: CGSize(bothDimensions: infoIconSide))
                .expandingHitArea(by: Constants.infoHitAreaInset)
        }
        .accessibilityLabel(Localization.commonLearnMore)
    }

    private func metric(_ metric: MarketCapViewModel.Metric, isLoading: Bool) -> some View {
        SwiftUI.Button {
            viewModel.onMetricTap(metric)
        } label: {
            metricContent(metric, isLoading: isLoading)
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
    }

    private func metricContent(_ metric: MarketCapViewModel.Metric, isLoading: Bool) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 0) {
                Text(metric.title)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)

                Text(metric.status)
                    .style(DesignSystem.Font.captionMediumToken, color: metric.appearance.textColor)
                    .shimmerPlaceholder(isLoading, variant: .custom(width: Constants.statusSkeletonSize.width, height: Constants.statusSkeletonSize.height, cornerRadius: Constants.skeletonCornerRadius))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(metric.value)
                    .style(Font.Tangem.Heading22.semibold, color: DesignSystem.Color.textPrimary)
                    .shimmerPlaceholder(isLoading, variant: .custom(width: Constants.valueSkeletonSize.width, height: Constants.valueSkeletonSize.height, cornerRadius: Constants.skeletonCornerRadius))

                MarketIndexScaleView(progress: isLoading ? 0 : metric.progress, size: .small)
                    .opacity(isLoading ? 0 : 1)
            }
        }
        .padding(Constants.cardPadding)
        .frame(maxWidth: .infinity, minHeight: Constants.cardMinHeight, alignment: .leading)
        .background(DesignSystem.Color.bgSecondary, in: RoundedRectangle(cornerRadius: Constants.cardCornerRadius, style: .circular))
    }
}

// MARK: - Constants

private extension MarketCapView {
    enum Constants {
        static let infoIconSide: CGFloat = 16
        static let infoHitAreaInset: CGFloat = 14
        static let cardPadding: CGFloat = 16
        static let cardMinHeight: CGFloat = 118
        static let cardCornerRadius: CGFloat = 24
        static let capSkeletonSize = CGSize(width: 96, height: 22)
        static let statusSkeletonSize = CGSize(width: 64, height: 14)
        static let valueSkeletonSize = CGSize(width: 32, height: 22)
        static let skeletonCornerRadius: CGFloat = 3
    }
}
