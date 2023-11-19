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

    private let iconSize = CGSize(width: 36, height: 36)

    init(viewModel: ExpressTokenItemViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        Button(action: viewModel.itemDidTap) {
            HStack(spacing: 12) {
                TokenIcon(tokenIconInfo: viewModel.tokenIconInfo, size: iconSize)
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

                if let fiatBalanceFormatted = viewModel.fiatBalanceFormatted {
                    SensitiveText(fiatBalanceFormatted)
                        .style(
                            Fonts.Regular.subheadline,
                            color: viewModel.isDisable ? Colors.Text.tertiary : Colors.Text.primary1
                        )
                }
            }

            HStack(spacing: .zero) {
                Text(viewModel.symbol)
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)

                Spacer(minLength: 4)

                if let balanceFormatted = viewModel.balanceFormatted {
                    SensitiveText(balanceFormatted)
                        .style(
                            Fonts.Regular.footnote,
                            color: viewModel.isDisable ? Colors.Text.disabled : Colors.Text.tertiary
                        )
                }
            }
        }
        .lineLimit(1)
    }
}

struct ExpressTokenItemView_Previews: PreviewProvider {
    static let viewModels = [
        ExpressTokenItemViewModel(
            id: "Bitcoin".hashValue,
            tokenIconInfo: TokenIconInfo(
                name: "",
                blockchainIconName: "bitcoin",
                imageURL: TokenIconURLBuilder().iconURL(id: "", size: .large),
                isCustom: false,
                customTokenColor: Color.red
            ),
            name: "Bitcoin",
            symbol: "BTC",
            balance: CurrencyAmount(value: 3.543, currency: .mock),
            fiatBalance: 1.23415 * 16345,
            isDisable: false,
            itemDidTap: {}
        ), ExpressTokenItemViewModel(
            id: "Ethereum".hashValue,
            tokenIconInfo: TokenIconInfo(
                name: "",
                blockchainIconName: "ethereum",
                imageURL: TokenIconURLBuilder().iconURL(id: "tether", size: .large),
                isCustom: false,
                customTokenColor: Color.red
            ),
            name: "Ethereum",
            symbol: "ETH",
            balance: CurrencyAmount(value: 3.543, currency: .mock),
            fiatBalance: 3.543 * 1341,
            isDisable: false,
            itemDidTap: {}
        ), ExpressTokenItemViewModel(
            id: "Tether".hashValue,
            tokenIconInfo: TokenIconInfo(
                name: "",
                blockchainIconName: "ethereum",
                imageURL: TokenIconURLBuilder().iconURL(id: "dai", size: .large),
                isCustom: false,
                customTokenColor: Color.red
            ),
            name: "Dai",
            symbol: "DAI",
            balance: CurrencyAmount(value: 3.543, currency: .mock),
            fiatBalance: 3.543 * 1341,
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
