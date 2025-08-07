//
//  SendNewAmountCompactTokenView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine
import TangemUI
import TangemAssets

struct SendNewAmountCompactTokenView: View {
    @ObservedObject var viewModel: SendNewAmountCompactTokenViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            headerView

            HStack(alignment: .top, spacing: .zero) {
                amountView

                Spacer()

                tokenIcon
            }
        }
        .padding(.all, 14)
    }

    private var headerView: some View {
        HStack(alignment: .center, spacing: .zero) {
            Text(.init(viewModel.walletNameTitle))
                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)

            Spacer()

            if let balance = viewModel.balance {
                LoadableTokenBalanceView(
                    state: balance,
                    style: .init(font: Fonts.Regular.footnote, textColor: Colors.Text.tertiary),
                    loader: .init(size: CGSize(width: 100, height: 18))
                )
            }
        }
    }

    @ViewBuilder
    private var amountView: some View {
        VStack(alignment: .leading, spacing: 2) {
            SendDecimalNumberTextField(viewModel: viewModel.amountTextFieldViewModel)
                .alignment(.leading)
                .prefixSuffixOptions(viewModel.amountFieldOptions)
                .minTextScale(SendAmountStep.Constants.amountMinTextScale)
                .appearance(.init(font: Fonts.Regular.title1))
                .allowsHitTesting(false) // This text field is read-only

            HStack(spacing: 8) {
                Text(viewModel.alternativeAmount ?? " ")
                    .style(Fonts.Regular.subheadline, color: Colors.Text.tertiary)
                    .lineLimit(1)

                highPriceImpactWarningView
            }
        }
    }

    private var tokenIcon: some View {
        VStack(alignment: .center, spacing: 4) {
            TokenIcon(tokenIconInfo: viewModel.tokenIconInfo, size: CGSize(width: 36, height: 36))

            Text(viewModel.tokenCurrencySymbol)
                .style(Fonts.Bold.footnote, color: Colors.Text.primary1)
                .lineLimit(1)
        }
    }

    @ViewBuilder
    private var highPriceImpactWarningView: some View {
        if let highPriceImpactWarning = viewModel.highPriceImpactWarning {
            HStack(spacing: 2) {
                Text(highPriceImpactWarning.percent)
                    .style(Fonts.Regular.subheadline, color: Colors.Text.attention)

                if #available(iOS 16.4, *) {
                    InfoButtonView(size: .medium, tooltipText: highPriceImpactWarning.infoMessage)
                        .color(Colors.Text.attention)
                } else {
                    Button(action: {
                        viewModel.userDidTapHighPriceImpactWarning(highPriceImpactWarning: highPriceImpactWarning)
                    }) {
                        Assets.infoCircle16.image
                            .renderingMode(.template)
                            .resizable()
                            .frame(width: 16, height: 16)
                            .foregroundStyle(Colors.Text.attention)
                    }
                }
            }
        }
    }
}
