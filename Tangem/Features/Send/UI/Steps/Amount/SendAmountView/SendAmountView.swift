//
//  SendAmountView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemUI
import TangemAccessibilityIdentifiers

struct SendAmountView: View {
    @ObservedObject var viewModel: SendAmountViewModel

    var body: some View {
        GroupedScrollView(spacing: 14) {
            amountContainer

            segmentControl
        }
        .onAppear(perform: viewModel.onAppear)
    }

    private var amountContainer: some View {
        VStack(spacing: 32) {
            walletInfoView

            amountContent
        }
        .defaultRoundedBackground(with: Colors.Background.action)
    }

    private var walletInfoView: some View {
        VStack(spacing: 4) {
            Text(viewModel.walletHeaderText)
                .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
                .lineLimit(1)

            SensitiveText(viewModel.balance)
                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                .lineLimit(1)
                .accessibilityIdentifier(SendAccessibilityIdentifiers.balanceLabel)
        }
        // Because the top padding have to be is 16 to the white background
        // But the bottom padding have to be is 12
        .padding(.top, 4)
    }

    private var amountContent: some View {
        VStack(spacing: 18) {
            TokenIcon(
                tokenIconInfo: viewModel.tokenIconInfo,
                size: CGSize(width: 36, height: 36),
                // Kingfisher shows a gray background even if it has a cached image
                forceKingfisher: false
            )

            VStack(spacing: 6) {
                SendDecimalNumberTextField(viewModel: viewModel.decimalNumberTextFieldViewModel)
                    .accessibilityIdentifier(SendAccessibilityIdentifiers.decimalNumberTextField)
                    .alignment(.center)
                    .prefixSuffixOptions(viewModel.currentFieldOptions)
                    .minTextScale(SendAmountStep.Constants.amountMinTextScale)

                // Keep empty text so that the view maintains its place in the layout
                Text(viewModel.alternativeAmount ?? " ")
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                    .lineLimit(1)

                bottomInfoText
            }
        }
    }

    private var bottomInfoText: some View {
        Group {
            switch viewModel.bottomInfoText {
            case .none:
                // Hold empty space
                Text(" ")
                    .style(Fonts.Regular.caption1, color: Colors.Text.warning)
            case .info(let string):
                Text(string)
                    .style(Fonts.Regular.caption1, color: Colors.Text.attention)
            case .error(let string):
                Text(string)
                    .style(Fonts.Regular.caption1, color: Colors.Text.warning)
            }
        }
        .multilineTextAlignment(.center)
        .lineLimit(2)
    }

    private var segmentControl: some View {
        GeometryReader { proxy in
            HStack(spacing: 8) {
                SendCurrencyPicker(
                    data: viewModel.currencyPickerData,
                    useFiatCalculation: viewModel.isFiatCalculation.asBinding
                )

                MainButton(title: Localization.sendMaxAmount, style: .secondary) {
                    viewModel.userDidTapMaxAmount()
                }
                .frame(width: proxy.size.width / 3)
            }
        }
    }
}
