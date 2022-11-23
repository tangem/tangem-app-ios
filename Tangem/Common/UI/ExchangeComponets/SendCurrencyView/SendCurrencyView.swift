//
//  SendCurrencyView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct SendCurrencyView: View {
    private var viewModel: SendCurrencyViewModel
    @Binding private var decimalValue: Decimal?

    private let tokenIconSize = CGSize(width: 36, height: 36)

    init(viewModel: SendCurrencyViewModel, decimalValue: Binding<Decimal?>) {
        self.viewModel = viewModel
        _decimalValue = decimalValue
    }

    var body: some View {
        VStack(spacing: 8) {
            headerLabels

            mainContent
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(Colors.Background.primary)
        .cornerRadius(14)
    }

    private var headerLabels: some View {
        HStack(spacing: 0) {
            Text("exchange_send_view_header".localized)
                .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

            Spacer()

            Text(viewModel.balanceString)
                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
        }
    }

    private var currencyContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            GroupedNumberTextField(decimalValue: $decimalValue)
                .maximumFractionDigits(viewModel.maximumFractionDigits)

            Text(viewModel.fiatValueString)
                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
        }
    }

    private var mainContent: some View {
        HStack(alignment: .top, spacing: 0) {
            currencyContent

            Spacer()

            VStack(spacing: 4) {
                TokenIconView(
                    viewModel: viewModel.tokenIcon,
                    size: tokenIconSize
                )

                Text(viewModel.tokenSymbol)
                    .style(Fonts.Bold.footnote, color: Colors.Text.primary1)
            }
            .padding(.trailing, 12)
        }
    }
}

struct SendCurrencyView_Preview: PreviewProvider {
    @State private static var decimalValue: Decimal? = 1000

    static let viewModel = SendCurrencyViewModel(
        balance: 3043.75,
        maximumFractionDigits: 8,
        fiatValue: 1000.71,
        tokenIcon: TokenIconViewModel(tokenItem: .blockchain(.bitcoin(testnet: false))),
        tokenSymbol: "BTC"
    )

    static var previews: some View {
        ZStack {
            Colors.Background.secondary

            SendCurrencyView(viewModel: viewModel, decimalValue: $decimalValue)
                .padding(.horizontal, 16)
        }
    }
}
