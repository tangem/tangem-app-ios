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

    private let iconSize = CGSize(bothDimensions: 46)

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 0) {
                IconView(url: viewModel.imageURL, customTokenColor: nil, size: iconSize, forceKingfisher: true)
                    .padding(.trailing, 12)

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 4) {
                        Text(viewModel.name)
                            .lineLimit(1)
                            .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)

                        Text(viewModel.symbol)
                            .lineLimit(1)
                            .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
                    }

                    HStack(spacing: 4) {
                        Text(viewModel.price)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)

                        TokenPriceChangeView(state: viewModel.priceChange)
                    }
                }

                Spacer(minLength: 24)

                if let priceHistory = viewModel.priceHistory {
                    LineChartView(
                        color: viewModel.priceHistoryChangeType.textColor,
                        data: priceHistory
                    )
                    .frame(width: 50, height: 37, alignment: .center)
                    .padding(.trailing, 24)
                }

                manageButton(for: viewModel.action)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
        .animation(nil) // Disable animations on scroll reuse
    }

    @ViewBuilder
    private func manageButton(for action: ManageTokensItemViewModel.Action) -> some View {
        ZStack {
            Button {
                viewModel.didTapAction(action)
            } label: {
                switch action {
                case .add:
                    AddButtonView()
                case .edit:
                    EditButtonView()
                case .info:
                    Assets.infoIconMini.image
                        .renderingMode(.template)
                        .foregroundColor(Colors.Icon.informative)
                }
            }

            AddButtonView()
                .hidden()

            EditButtonView()
                .hidden()
        }
    }
}

private struct AddButtonView: View {
    var body: some View {
        TextButtonView(text: Localization.manageTokensAdd, foreground: Colors.Text.primary2, background: Colors.Button.primary)
    }
}

private struct EditButtonView: View {
    var body: some View {
        TextButtonView(text: Localization.manageTokensEdit, foreground: Colors.Text.primary1, background: Colors.Button.secondary)
    }
}

private struct TextButtonView: View {
    let text: String
    let foreground: Color
    let background: Color

    var body: some View {
        Text(text)
            .style(Fonts.Bold.caption1, color: foreground)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(background)
            .clipShape(Capsule())
    }
}

struct CurrencyViewNew_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            ManageTokensItemView(viewModel: ManageTokensItemViewModel(
                imageURL: URL(string: "https://raw.githubusercontent.com/trustwallet/assets/master/blockchains/bitcoin/info/logo.png")!,
                name: "Bitcoin",
                symbol: "BTC",
                price: "$23,034.83",
                priceChange: .loaded(signType: .positive, text: "10.5%"),
                priceHistory: [1, 7, 3, 5, 13],
                action: .add,
                didTapAction: { _ in }
            ))

            ManageTokensItemView(viewModel: ManageTokensItemViewModel(
                imageURL: URL(string: "https://raw.githubusercontent.com/trustwallet/assets/master/blockchains/ethereum/info/logo.png")!,
                name: "Ethereum",
                symbol: "ETH",
                price: "$1,340.33",
                priceChange: .loaded(signType: .negative, text: "10.5%"),
                priceHistory: [1, 7, 3, 5, 13].reversed(),
                action: .add,
                didTapAction: { _ in }
            ))

            ManageTokensItemView(viewModel: ManageTokensItemViewModel(
                imageURL: URL(string: "https://raw.githubusercontent.com/trustwallet/assets/master/blockchains/solana/info/logo.png")!,
                name: "Solana",
                symbol: "SOL",
                price: "$33.00",
                priceChange: .loaded(signType: .positive, text: "1.3%"),
                priceHistory: [1, 7, 3, 5, 13],
                action: .add,
                didTapAction: { _ in }
            ))

            ManageTokensItemView(viewModel: ManageTokensItemViewModel(
                imageURL: URL(string: "https://raw.githubusercontent.com/trustwallet/assets/master/blockchains/polygon/info/logo.png")!,
                name: "Polygon",
                symbol: "MATIC",
                price: "$34.83",
                priceChange: .loaded(signType: .positive, text: "0.0%"),
                priceHistory: [4, 7, 3, 5, 4],
                action: .edit,
                didTapAction: { _ in }
            ))

            ManageTokensItemView(viewModel: ManageTokensItemViewModel(
                imageURL: URL(string: "https://raw.githubusercontent.com/trustwallet/assets/master/blockchains/acalaevm/info/logo.png")!,
                name: "Very long token name is very long",
                symbol: "BUS",
                price: "$23,341,324,034.83",
                priceChange: .loaded(signType: .positive, text: "1,444,340,340.0%"),
                priceHistory: [1, 7, 3, 5, 13],
                action: .info,
                didTapAction: { _ in }
            ))

            ManageTokensItemView(viewModel: ManageTokensItemViewModel(
                imageURL: nil,
                name: "Custom Token",
                symbol: "CT",
                price: "$100.83",
                priceChange: .loaded(signType: .positive, text: "1.0%"),
                priceHistory: nil,
                action: .add,
                didTapAction: { _ in }
            ))

            Spacer()
        }
    }
}
