//
//  SendCurrencyView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct SendCurrencyViewModel: Identifiable {
    var id: Int { hashValue }
    let tokenIcon: TokenIconViewModel
    
    var balanceString: String {
        "Balance: \(balance.groupedFormatted())"
    }
    
    var fiatValueString: String {
        fiatValue.currencyFormatted(code: AppSettings.shared.selectedCurrencyCode)
    }
    
    private let balance: Decimal
    private var fiatValue: Decimal

    init(
        balance: Decimal,
        fiatValue: Decimal,
        tokenIcon: TokenIconViewModel
    ) {
        self.balance = balance
        self.fiatValue = fiatValue
        self.tokenIcon = tokenIcon
    }

    mutating func update(fiatValue: Decimal) {
        self.fiatValue = fiatValue
    }
}

extension SendCurrencyViewModel: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(balance)
        hasher.combine(fiatValue)
        hasher.combine(tokenIcon)
    }
}

struct SendCurrencyView: View {
    private var viewModel: SendCurrencyViewModel
    @Binding private var textFieldText: Decimal?

    init(
        viewModel: SendCurrencyViewModel,
        textFieldText: Binding<Decimal?>
    ) {
        self.viewModel = viewModel
        _textFieldText = textFieldText
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
            TextField("0", value: $textFieldText, formatter: NumberFormatter.grouped)
                .style(Fonts.Regular.title1, color: Colors.Text.primary1)
                .keyboardType(.numberPad)

            Text(viewModel.fiatValueString)
                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
        }
    }

    private var mainContent: some View {
        HStack(spacing: 0) {
            currencyContent

            Spacer()

            TokenIconView(viewModel: viewModel.tokenIcon)
                .padding(.trailing, 16)
        }
    }
}

struct SendCurrencyView_Preview: PreviewProvider {
    @State private static var text: Decimal? = nil
    static let viewModel = SendCurrencyViewModel(
        balance: 3043.75,
        fiatValue: 1000.71,
        tokenIcon: TokenIconViewModel(tokenItem: .blockchain(.bitcoin(testnet: false)))
    )

    static var previews: some View {
        ZStack {
            Colors.Background.secondary

            SendCurrencyView(viewModel: viewModel, textFieldText: $text)
                .padding(.horizontal, 16)
        }
    }
}
