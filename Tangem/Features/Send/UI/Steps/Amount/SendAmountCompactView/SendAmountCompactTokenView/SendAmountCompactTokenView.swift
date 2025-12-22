//
//  SendAmountCompactTokenView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine
import TangemUI
import TangemAssets
import TangemAccessibilityIdentifiers

struct SendAmountCompactTokenView: View {
    @ObservedObject var viewModel: SendAmountCompactTokenViewModel

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
            switch viewModel.title {
            case .text(let text):
                Text(text)
                    .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
            case .header(let header):
                SendTokenHeaderView(header: header)
            }

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
            ZStack {
                // We use hidden `Text` here to calculate constant height without `minimumScaleFactor`
                Text(viewModel.amountText)
                    .style(Fonts.Regular.title1, color: Colors.Text.primary1)
                    .hidden(true)

                Text(viewModel.amountText)
                    .style(Fonts.Regular.title1, color: Colors.Text.primary1)
                    .minimumScaleFactor(SendAmountStep.Constants.amountMinTextScale)
                    .accessibilityIdentifier(SendAccessibilityIdentifiers.sendAmountViewValue)
            }

            HStack(spacing: 4) {
                Text(viewModel.alternativeAmount ?? " ")
                    .style(Fonts.Regular.subheadline, color: Colors.Text.tertiary)

                highPriceImpactWarningView
            }
        }
        .lineLimit(1)
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
                if highPriceImpactWarning.isHighPriceImpact {
                    Text(highPriceImpactWarning.percent)
                        .style(Fonts.Regular.subheadline, color: Colors.Text.attention)
                        .padding(.leading, 4)
                }

                InfoButtonView(size: .medium, tooltipText: highPriceImpactWarning.infoMessage)
                    .color(highPriceImpactWarning.isHighPriceImpact ? Colors.Text.attention : Colors.Text.tertiary)
            }
        }
    }
}
