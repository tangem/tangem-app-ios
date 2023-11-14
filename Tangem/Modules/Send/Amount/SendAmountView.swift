//
//  SendAmountView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct SendAmountView: View {
    let namespace: Namespace.ID

    @ObservedObject var viewModel: SendAmountViewModel

    private let iconSize = CGSize(bothDimensions: 36)

    var body: some View {
        GroupedScrollView {
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
            .matchedGeometryEffect(id: "amount", in: namespace)

            HStack {
                Picker("", selection: $viewModel.currencyOption) {
                    Text(viewModel.cryptoCurrencyCode)
                        .tag(SendAmountViewModel.CurrencyOption.crypto)

                    Text(viewModel.fiatCurrencyCode)
                        .tag(SendAmountViewModel.CurrencyOption.fiat)
                }
                .pickerStyle(.segmented)

                MainButton(title: Localization.sendMaxAmount, style: .secondary) {
                    viewModel.didTapMaxAmount()
                }
            }
        }
        .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
    }
}

struct SendAmountView_Previews: PreviewProvider {
    @Namespace static var namespace

    static var previews: some View {
        SendAmountView(namespace: namespace, viewModel: SendAmountViewModel(input: SendAmountViewModelInputMock()))
    }
}
