//
//  SendAmountContainerView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct SendAmountContainerView: View {
    @ObservedObject var viewModel: SendAmountContainerViewModel

    private let iconSize = CGSize(bothDimensions: 36)

    var body: some View {
        GroupedSection(viewModel) { viewModel in
            VStack(spacing: 0) {
                Text(viewModel.walletName)
                    .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
                    .lineLimit(1)
                    .padding(.top, 18)

                Text(viewModel.balance)
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                    .lineLimit(1)
                    .padding(.top, 4)

                TokenIcon(
                    name: viewModel.tokenIconName,
                    imageURL: viewModel.tokenIconURL,
                    customTokenColor: viewModel.tokenIconCustomTokenColor,
                    blockchainIconName: viewModel.tokenIconBlockchainIconName,
                    isCustom: viewModel.isCustomToken,
                    size: iconSize
                )
                .padding(.top, 34)

                DecimalNumberTextField(
                    decimalValue: viewModel.decimalValue,
                    decimalNumberFormatter: .init(maximumFractionDigits: viewModel.amountFractionDigits),
                    font: Fonts.Regular.title1
                )
                .padding(.top, 16)

                Text(viewModel.amountAlternative)
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                    .lineLimit(1)
                    .padding(.top, 6)

                // Keep empty text so that the view maintains its place in the layout
                Text(viewModel.error ?? " ")
                    .style(Fonts.Regular.caption1, color: Colors.Text.warning)
                    .lineLimit(1)
                    .padding(.top, 6)
                    .padding(.bottom, 12)
            }
        }
        .contentAlignment(.center)
    }
}

#Preview("Figma") {
    GroupedScrollView {
        SendAmountContainerView(
            viewModel: SendAmountContainerViewModel(
                walletName: "Family Wallet",
                balance: "2 130,88 USDT (2 129,92 $)",
                tokenIconName: "tether",
                tokenIconURL: TokenIconURLBuilder().iconURL(id: "tether"),
                tokenIconCustomTokenColor: nil,
                tokenIconBlockchainIconName: "ethereum.fill",
                isCustomToken: false,
                amountFractionDigits: 2,
                amountAlternativePublisher: .just(output: "1 000 010,99 USDT"),
                decimalValue: .constant(DecimalNumberTextField.DecimalValue.internal(0)),
                errorPublisher: .just(output: "Insufficient funds for transfer")
            )
        )
    }
    .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
}

#Preview("Edge cases") {
    GroupedScrollView {
        SendAmountContainerView(
            viewModel: SendAmountContainerViewModel(
                walletName: "Family Wallet Wallet Wallet Wallet Wallet Wallet Wallet Wallet Wallet Wallet Wallet Wallet Wallet Wallet Wallet",
                balance: "2 130 130 130 130 130 130 130 130 130,88 USDT (2 129 129 129 129 129 129 129 129 129 129 129,92 $)",
                tokenIconName: "tether",
                tokenIconURL: TokenIconURLBuilder().iconURL(id: "tether"),
                tokenIconCustomTokenColor: nil,
                tokenIconBlockchainIconName: "ethereum.fill",
                isCustomToken: false,
                amountFractionDigits: 2,
                amountAlternativePublisher: .just(output: "1 000 000 000 000 000 000 000 000 000 000 000 000 000 000 000,00 $"),
                decimalValue: .constant(DecimalNumberTextField.DecimalValue.internal(9999999999)),
                errorPublisher: .just(output: "Insufficient funds for transfer for transfer for transfer for transfer for transfer for transfer for transfer for transfer for transfer for transfer for transfer for transfer for transfer for transfer for transfer for transfer for transfer for transfer for transfer for transfer for transfer for transfer")
            )
        )
    }
    .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
}
