//
//  ExpressTokenItemView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct ExpressTokenItemView: View {
    private let viewModel: ExpressTokenItemViewModel

    init(viewModel: ExpressTokenItemViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        Button(action: viewModel.itemDidTap) {
            HStack(spacing: 12) {
                TokenIconItemView(viewModel: viewModel.tokenIconItem)
                    .saturation(viewModel.isDisable ? 0 : 1)

                infoView
            }
            .padding(.vertical, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var infoView: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: .zero) {
                Text(viewModel.name)
                    .style(
                        Fonts.Bold.subheadline,
                        color: viewModel.isDisable ? Colors.Text.tertiary : Colors.Text.primary1
                    )

                Spacer(minLength: 4)

                SensitiveText(viewModel.fiatBalance)
                    .style(
                        Fonts.Regular.subheadline,
                        color: viewModel.isDisable ? Colors.Text.tertiary : Colors.Text.primary1
                    )
            }

            HStack(spacing: .zero) {
                Text(viewModel.symbol)
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)

                Spacer(minLength: 4)

                SensitiveText(viewModel.balance)
                    .style(
                        Fonts.Regular.footnote,
                        color: viewModel.isDisable ? Colors.Text.disabled : Colors.Text.tertiary
                    )
            }
        }
        .lineLimit(1)
    }
}

struct ExpressTokenItemView_Previews: PreviewProvider {
    static let viewModels = [
        ExpressTokenItemViewModel(
            id: "Bitcoin".hashValue,
            tokenIconItem: TokenIconItemViewModel(
                imageURL: TokenIconURLBuilder().iconURL(id: "bitcoin", size: .large),
                networkURL: nil
            ),
            name: "Bitcoin",
            symbol: "BTC",
            balance: "3.543 BTC",
            fiatBalance: "$3.543",
            isDisable: false,
            itemDidTap: {}
        ), ExpressTokenItemViewModel(
            id: "Ethereum".hashValue,
            tokenIconItem: TokenIconItemViewModel(
                imageURL: TokenIconURLBuilder().iconURL(id: "tether", size: .large),
                networkURL: TokenIconURLBuilder().iconURL(id: "ethereum", size: .small)
            ),
            name: "Ethereum",
            symbol: "ETH",
            balance: "3.543 ETH",
            fiatBalance: "$3.543",
            isDisable: false,
            itemDidTap: {}
        ), ExpressTokenItemViewModel(
            id: "Tether".hashValue,
            tokenIconItem: TokenIconItemViewModel(
                imageURL: TokenIconURLBuilder().iconURL(id: "dai", size: .large),
                networkURL: TokenIconURLBuilder().iconURL(id: "ethereum", size: .small)
            ),
            name: "Dai",
            symbol: "DAI",
            balance: "3.543 DAI",
            fiatBalance: "$3.543",
            isDisable: true,
            itemDidTap: {}
        ),
    ]

    static var previews: some View {
        ZStack {
            Colors.Background.secondary

            GroupedSection(viewModels) {
                ExpressTokenItemView(viewModel: $0)
            }
        }
    }
}
