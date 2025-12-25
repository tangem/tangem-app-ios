//
//  MarketTokenItemView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAccessibilityIdentifiers
import TangemAssets
import TangemUI

struct MarketTokenItemView: View {
    @ObservedObject var viewModel: MarketTokenItemViewModel

    let cellWidth: CGFloat

    private var textBlockWidth: CGFloat {
        let textWidth = cellWidth - Constants.widthNeededForItemsExceptTextBlock
        return textWidth
    }

    var body: some View {
        Button(action: {
            viewModel.didTapAction?()
        }) {
            HStack(spacing: Constants.itemsHorizontalSpacing) {
                IconView(url: viewModel.imageURL, size: Constants.imageSize, forceKingfisher: true)
                    .padding(.trailing, Constants.imageTrailingPadding)

                VStack(spacing: 3) {
                    tokenInfoView

                    tokenMarketPriceView
                }

                priceHistoryView
            }
            .padding(.horizontal, Constants.horizontalViewPadding)
            .padding(.vertical, 14)
        }
        .accessibilityIdentifier(
            MarketsAccessibilityIdentifiers.marketsListTokenItem(uniqueId: viewModel.name))
    }

    private var tokenInfoView: some View {
        HStack(alignment: .firstTextBaseline, spacing: Constants.textBlockItemsSpacing) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(viewModel.name)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)

                Text(viewModel.symbol)
                    .lineLimit(1)
                    .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
            }
            .frame(minWidth: 0.3 * textBlockWidth, maxWidth: .infinity, alignment: .leading)

            Text(viewModel.priceValue)
                .lineLimit(1)
                .blinkForegroundColor(
                    publisher: viewModel.$priceChangeAnimation,
                    positiveColor: Colors.Text.accent,
                    negativeColor: Colors.Text.warning,
                    originalColor: Colors.Text.primary1
                )
                .style(Fonts.Regular.footnote, color: Colors.Text.primary1)
        }
    }

    private var tokenMarketPriceView: some View {
        HStack(spacing: .zero) {
            HStack(alignment: .firstTextBaseline, spacing: Constants.textBlockItemsSpacing) {
                if let marketRating = viewModel.marketRating {
                    Text(marketRating)
                        .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
                        .roundedBackground(with: Colors.Field.primary, verticalPadding: .zero, horizontalPadding: 5, radius: 4)
                }

                Text(viewModel.marketCap)
                    .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)

                if let maxApy = viewModel.maxApy {
                    Text(maxApy)
                        .style(Fonts.Regular.caption2, color: Colors.Text.secondary)
                        .lineLimit(1)
                        .padding(EdgeInsets(top: 3, leading: 5, bottom: 2, trailing: 5))
                        .overlay(content: {
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .stroke(Colors.Stroke.primary, lineWidth: 1)
                        })
                        .layoutPriority(10)
                }
            }
            .frame(minWidth: 0.32 * textBlockWidth, maxWidth: .infinity, alignment: .leading)

            TokenPriceChangeView(state: viewModel.priceChangeState)
        }
    }

    private var priceHistoryView: some View {
        VStack {
            if let charts = viewModel.charts {
                LineChartView(
                    color: viewModel.priceChangeState.signType?.textColor ?? Colors.Text.tertiary,
                    data: charts
                )
            } else {
                makeSkeletonView(by: Constants.skeletonMediumWidthValue)
            }
        }
        .frame(size: Constants.chartSize, alignment: .center)
    }

    private func makeSkeletonView(by value: String) -> some View {
        Text(value)
            .style(Fonts.Bold.caption1, color: Colors.Text.primary1)
            .skeletonable(isShown: true)
    }
}

extension MarketTokenItemView {
    enum Constants {
        static let textBlockItemsSpacing = 4.0
        static let horizontalViewPadding: CGFloat = 16.0
        static let imageSize: CGSize = .init(bothDimensions: 36)
        static let imageTrailingPadding: CGFloat = 2
        static let itemsHorizontalSpacing: CGFloat = 10.0
        static let chartSize: CGSize = .init(width: 56, height: 24)
        static let skeletonMediumWidthValue: String = "---------"
        static let skeletonSmallWidthValue: String = "------"

        static let widthNeededForItemsExceptTextBlock: CGFloat = horizontalViewPadding * 2 + imageSize.width + chartSize.width + itemsHorizontalSpacing * 2 + imageTrailingPadding
    }
}

#Preview {
    let tokens = DummyMarketTokenModelFactory().list()

    return GeometryReader { proxy in
        ScrollView(.vertical) {
            ForEach(tokens.indexed(), id: \.1.id) { index, token in
                MarketTokenItemView(
                    viewModel: .init(
                        tokenModel: token,
                        marketCapFormatter: .init(divisorsList: AmountNotationSuffixFormatter.Divisor.defaultList, baseCurrencyCode: "USD", notationFormatter: .init()),
                        chartsProvider: .init(),
                        filterProvider: .init(),
                        onTapAction: nil
                    ),
                    cellWidth: proxy.size.width
                )
            }
        }
    }
}
