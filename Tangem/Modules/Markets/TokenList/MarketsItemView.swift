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

                tokenInfo
            }

            Spacer(minLength: 24)

            priceHistoryView
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 15)
        .animation(nil) // Disable animations on scroll reuse
    }

    private var tokenInfo: some View {
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
                Text(viewModel.priceValue)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                    .skeletonable(isShown: viewModel.isLoading, radius: 3)

                if !viewModel.isLoading {
                    TokenPriceChangeView(state: viewModel.priceChangeState)
                }
            }
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
        .frame(width: 50, height: 37, alignment: .center)
        .padding(.trailing, 24)
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
