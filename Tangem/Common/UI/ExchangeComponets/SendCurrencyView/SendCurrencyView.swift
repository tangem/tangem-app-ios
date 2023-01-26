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
    private var didTapTokenView: () -> Void = {}
    private var didTapMaxAmountAction: (() -> Void)?

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
            Text(Localization.exchangeSendViewHeader)
                .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

            Spacer()

            Text(viewModel.balanceString)
                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
        }
    }

    private var currencyContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            SendGroupedNumberTextField(decimalValue: $decimalValue, maximumFractionDigits: viewModel.maximumFractionDigits)
                .maximumFractionDigits(viewModel.maximumFractionDigits)
                .didTapMaxAmount { didTapMaxAmountAction?() }

            Text(viewModel.fiatValueString)
                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
        }
    }

    private var mainContent: some View {
        HStack(alignment: .top, spacing: 0) {
            currencyContent

            Spacer()

            SwappingTokenIconView(viewModel: viewModel.tokenIcon)
                .onTap(viewModel.isChangeable ? didTapTokenView : nil)
        }
    }
}

// MARK: - Setupable

extension SendCurrencyView: Setupable {
    func didTapMaxAmount(_ action: @escaping () -> Void) -> Self {
        map { $0.didTapMaxAmountAction = action }
    }

    func didTapTokenView(_ block: @escaping () -> Void) -> Self {
        map { $0.didTapTokenView = block }
    }
}

struct SendCurrencyView_Preview: PreviewProvider {
    @State private static var decimalValue: Decimal? = nil

    static let viewModel = SendCurrencyViewModel(
        balance: 3043.75,
        maximumFractionDigits: 8,
        isChangeable: false,
        fiatValue: 1000.71,
        tokenIcon: SwappingTokenIconViewModel(
            state: .loaded(
                imageURL: TokenIconURLBuilderMock().iconURL(id: "bitcoin", size: .large),
                symbol: "BTC"
            )
        )
    )

    static let viewModelLocked = SendCurrencyViewModel(
        balance: 0.02,
        maximumFractionDigits: 8,
        isChangeable: true,
        fiatValue: 0.02,
        tokenIcon: SwappingTokenIconViewModel(
            state: .loaded(
                imageURL: TokenIconURLBuilderMock().iconURL(id: "bitcoin", size: .large),
                symbol: "BTC"
            )
        )
    )

    static var previews: some View {
        ZStack {
            Colors.Background.secondary

            VStack {
                SendCurrencyView(viewModel: viewModel, decimalValue: $decimalValue)

                SendCurrencyView(viewModel: viewModelLocked, decimalValue: $decimalValue)
            }
            .padding(.horizontal, 16)
        }
    }
}
