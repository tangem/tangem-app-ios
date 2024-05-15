//
//  ManageTokensItemView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct ManageTokensItemView: View {
    @ObservedObject var viewModel: ManageTokensItemViewModel

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

struct CurrencyViewNew_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            ManageTokensItemView(viewModel: ManageTokensItemViewModel(
                coinModel: CoinModel(
                    id: "",
                    name: "Bitcoin",
                    symbol: "BTC",
                    items: []
                ),
                priceValue: "$23,034.83",
                priceChangeState: .loaded(signType: .positive, text: "10.5%"),
                priceHistory: [1, 7, 3, 5, 13],
                state: .loaded
            ))

            ManageTokensItemView(viewModel: ManageTokensItemViewModel(
                coinModel: CoinModel(
                    id: "",
                    name: "Ethereum",
                    symbol: "ETH",
                    items: []
                ),
                priceValue: "$1,340.33",
                priceChangeState: .loaded(signType: .negative, text: "10.5%"),
                priceHistory: [1, 7, 3, 5, 13].reversed(),
                state: .loaded
            ))

            ManageTokensItemView(viewModel: ManageTokensItemViewModel(
                coinModel: CoinModel(
                    id: "",
                    name: "Solana",
                    symbol: "SOL",
                    items: []
                ),
                priceValue: "$33.00",
                priceChangeState: .loaded(signType: .positive, text: "1.3%"),
                priceHistory: [1, 7, 3, 5, 13],
                state: .loaded
            ))

            ManageTokensItemView(viewModel: ManageTokensItemViewModel(
                coinModel: CoinModel(
                    id: "",
                    name: "Polygon",
                    symbol: "MATIC",
                    items: []
                ),
                priceValue: "$34.83",
                priceChangeState: .loaded(signType: .positive, text: "0.0%"),
                priceHistory: [4, 7, 3, 5, 4],
                state: .loaded
            ))

            ManageTokensItemView(viewModel: ManageTokensItemViewModel(
                coinModel: CoinModel(
                    id: "",
                    name: "Very long token name is very long",
                    symbol: "BUS",
                    items: []
                ),
                priceValue: "$23,341,324,034.83",
                priceChangeState: .loaded(signType: .positive, text: "1,444,340,340.0%"),
                priceHistory: [1, 7, 3, 5, 13],
                state: .loaded
            ))

            ManageTokensItemView(viewModel: ManageTokensItemViewModel(
                coinModel: CoinModel(
                    id: "",
                    name: "Custom Token",
                    symbol: "CT",
                    items: []
                ),
                priceValue: "$100.83",
                priceChangeState: .loaded(signType: .positive, text: "1.0%"),
                priceHistory: nil,
                state: .loaded
            ))

            Spacer()
        }
    }
}
