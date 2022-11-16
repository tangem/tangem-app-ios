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

    let balance: String
    var fiatValue: String
    let tokenItem: TokenItem

//    [REDACTED_USERNAME] var valueTextField: String

    init(
        balance: String,
        fiatValue: String,
        tokenItem: TokenItem // ,
//        valueTextField: Binding<String>
    ) {
        self.balance = balance
        self.fiatValue = fiatValue
        self.tokenItem = tokenItem
//        _valueTextField = valueTextField
    }
}

extension SendCurrencyViewModel: Hashable {
    static func == (lhs: SendCurrencyViewModel, rhs: SendCurrencyViewModel) -> Bool {
        lhs.hashValue == rhs.hashValue
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(balance)
        hasher.combine(fiatValue)
        hasher.combine(tokenItem)
//        hasher.combine(valueTextField)
    }
}

struct SendCurrencyView: View {
    private var viewModel: SendCurrencyViewModel
    @Binding private var textFieldText: String
    
    init(
        viewModel: SendCurrencyViewModel,
        textFieldText: Binding<String>
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
            Text("You Send")
                .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

            Spacer()

            Text(viewModel.balance)
                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
        }
    }

    private var currencyContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("0", text: $textFieldText)
                .style(Fonts.Regular.title1, color: Colors.Text.primary1)
                .keyboardType(.numberPad)

            Text(viewModel.fiatValue)
                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
        }
    }

    private var mainContent: some View {
        HStack(spacing: 0) {
            currencyContent

            Spacer()

            TokenIconView(tokenItem: viewModel.tokenItem)
                .padding(.trailing, 16)
        }
    }
}

struct SendCurrencyView_Preview: PreviewProvider {
    static let viewModel = SendCurrencyViewModel(
        balance: "Balance: 3 043,75",
        fiatValue: "1 000,71 $",
        tokenItem: .blockchain(.bitcoin(testnet: false)) // ,
//        valueTextField: .constant("")
    )
    
    @State private static var text = ""

    static var previews: some View {
        ZStack {
            Colors.Background.secondary

            SendCurrencyView(viewModel: viewModel, textFieldText: $text)
                .padding(.horizontal, 16)
        }
    }
}
