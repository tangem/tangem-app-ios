//
//  MarketsItemView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct MarketsItemView: View {
    @ObservedObject var viewModel: MarketsItemViewModel

    private let iconSize = CGSize(bothDimensions: 36)

    var body: some View {
        HStack {
            HStack(spacing: 12) {
                IconView(url: viewModel.imageURL, size: iconSize, forceKingfisher: true)
                    .skeletonable(isShown: viewModel.isLoading, radius: iconSize.height / 2)

                tokenInfoView
            }

            Spacer(minLength: 12)

            HStack(spacing: 10) {
                tokenPriceView

                priceHistoryView
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 15)
        .animation(nil) // Disable animations on scroll reuse
    }

    private var tokenInfoView: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstBaselineCustom, spacing: 4) {
                Text(viewModel.name)
                    .lineLimit(1)
                    .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)
                    .skeletonable(isShown: viewModel.isLoading, radius: 3)

                Text(viewModel.symbol)
                    .lineLimit(1)
                    .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
            }

            HStack(spacing: 6) {
                Text(viewModel.marketRaiting)
                    .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
                    .skeletonable(isShown: viewModel.isLoading, radius: 3)
                    .padding(.horizontal, 5)
                    .background(Colors.Field.primary)
                    .cornerRadiusContinuous(4)

                Text(viewModel.marketCap)
                    .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
                    .skeletonable(isShown: viewModel.isLoading, radius: 3)
            }
        }
    }

    private var tokenPriceView: some View {
        VStack(alignment: .trailing, spacing: 3) {
            Text(viewModel.priceValue)
                .lineLimit(1)
                .truncationMode(.middle)
                .style(Fonts.Regular.footnote, color: Colors.Text.primary1)
                .skeletonable(isShown: viewModel.isLoading, radius: 3)

            TokenPriceChangeView(state: viewModel.priceChangeState)
                .skeletonable(isShown: viewModel.isLoading, radius: 3)
        }
    }

    private var priceHistoryView: some View {
        VStack {
            if let priceHistory = viewModel.priceHistory {
                LineChartView(
                    color: viewModel.priceHistoryChangeType.textColor,
                    data: priceHistory
                )
            }
        }
        .frame(width: 56, height: 32, alignment: .center)
    }
}

#Preview {
    let tokens = DummyMarketTokenModelFactory().list()

    return ScrollView(.vertical) {
        ForEach((1 ..< tokens.count).reversed(), id: \.self) {
            MarketsItemView(
                viewModel: MarketsItemViewModel(
                    .init(
                        token: tokens[$0],
                        priceValue: Bool.random() ? "$1,340.33" : "$23,341,324,034.83",
                        priceChangeState: .loaded(signType: Bool.random() ? .positive : .negative, text: "\(Float.random(in: 0 ..< 10))%"),
                        priceHistory: [1, 7, 3, 5, 13],
                        state: .loaded
                    )
                )
            )
        }
    }
}
