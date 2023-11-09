//
//  SendAmountContainerView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

class SendAmountContainerViewModel: Identifiable {
    let walletName: String = "Family Wallet"
    let balance: String = "2 130,88 USDT (2 129,92 $)"

    let tokenIconName: String = "tether"
    let tokenIconURL: URL? = TokenIconURLBuilder().iconURL(id: "tether")
    let tokenIconCustomTokenColor: Color? = nil
    let tokenIconBlockchainIconName: String? = "ethereum.fill"
    let isCustomToken: Bool = false

    var decimalValue: Binding<DecimalNumberTextField.DecimalValue?> = .constant(DecimalNumberTextField.DecimalValue.internal(1))
    var amountInput: Binding<String> = .constant("0,00")
    let amountPlaceholder: String = "0,00"

    let amountFractionDigits = 2

    let amountAlternative: String = "0,00 $"

    var error: String? = "Insufficient funds for transfer"
}

struct SendAmountContainerView: View {
    let viewModel: SendAmountContainerViewModel
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

                DecimalNumberTextField(decimalValue: viewModel.decimalValue, decimalNumberFormatter: .init(maximumFractionDigits: viewModel.amountFractionDigits))
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
        SendAmountContainerView(viewModel: SendAmountContainerViewModel())
    }
    .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
}
