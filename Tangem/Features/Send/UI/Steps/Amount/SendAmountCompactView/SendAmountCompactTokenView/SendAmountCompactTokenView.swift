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
                    .style(Fonts.Bold.footnote, color: DesignSystem.Color.textSecondary)
            case .header(let header):
                SendTokenHeaderView(header: header)
            }

            Spacer()

            if let balance = viewModel.balance {
                LoadableBalanceView(
                    state: balance,
                    style: .init(font: Fonts.Regular.footnote, textColor: DesignSystem.Color.textSecondary),
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
                Text(viewModel.formattedAmount ?? " ")
                    .style(Fonts.Regular.title1, color: DesignSystem.Color.textPrimary)
                    .hidden(true)

                Text(viewModel.formattedAmount ?? " ")
                    .style(Fonts.Regular.title1, color: DesignSystem.Color.textPrimary)
                    .minimumScaleFactor(SendAmountStep.Constants.amountMinTextScale)
                    .accessibilityIdentifier(SendAccessibilityIdentifiers.sendAmountViewValue)
            }

            HStack(spacing: 4) {
                Text(viewModel.formattedAlternativeAmount ?? " ")
                    .style(Fonts.Regular.subheadline, color: DesignSystem.Color.textSecondary)

                highPriceImpactWarningView
            }
        }
        .lineLimit(1)
    }

    private var tokenIcon: some View {
        VStack(alignment: .center, spacing: 4) {
            TokenIcon(tokenIconInfo: viewModel.tokenIconInfo, size: CGSize(width: 36, height: 36))

            Text(viewModel.tokenCurrencySymbol)
                .style(Fonts.Bold.footnote, color: DesignSystem.Color.textPrimary)
                .lineLimit(1)
        }
    }

    @ViewBuilder
    private var highPriceImpactWarningView: some View {
        if let highPriceImpactWarning = viewModel.highPriceImpactWarning {
            switch highPriceImpactWarning.level {
            case .negligible:
                InfoButtonView(size: .small, tooltipText: highPriceImpactWarning.infoMessage)
            case .warningLoss:
                priceImpactHStack(warning: highPriceImpactWarning, color: DesignSystem.Color.textAccentYellow)
            case .highLossLowAmount, .highLossHighAmount:
                priceImpactHStack(warning: highPriceImpactWarning, color: DesignSystem.Color.textAccentRed)
            }
        }
    }

    private func priceImpactHStack(warning: SendAmountCompactTokenViewModel.HighPriceImpactWarning, color: Color) -> some View {
        HStack(spacing: 2) {
            Text(warning.percent)
                .style(Fonts.Regular.subheadline, color: color)
                .padding(.leading, 4)

            InfoButtonView(size: .small, tooltipText: warning.infoMessage)
                .color(color)
                .accessibilityIdentifier(SendAccessibilityIdentifiers.priceImpactInfoButton)
        }
    }
}
