//
//  NewOnrampAmountView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemLocalization
import TangemAccessibilityIdentifiers

struct NewOnrampAmountView: View {
    @ObservedObject var viewModel: NewOnrampAmountViewModel

    var body: some View {
        content
            .infinityFrame(axis: .horizontal)
            .defaultRoundedBackground(with: Colors.Background.action, verticalPadding: 50, horizontalPadding: 16)
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.fiatItem {
        case .some(let fiatItem):
            loadedContent(fiatItem: fiatItem)
        case .none:
            loadingContent
                .environment(\.isShimmerActive, true)
        }
    }

    @ViewBuilder
    private var loadingContent: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                // Title
                RoundedRectangle(cornerRadius: 4)
                    .fill(Colors.Field.focused)
                    .frame(width: 75, height: 16)
                    .padding(.vertical, 1)
                    .shimmer()

                VStack(spacing: 4) {
                    // Text field
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Colors.Field.focused)
                        .frame(width: 140, height: 42)
                        .shimmer()

                    // Crypto amount
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Colors.Field.focused)
                        .frame(width: 80, height: 18)
                        .shimmer()
                }
            }

            // Fiat token icon
            Capsule()
                .fill(Colors.Field.focused)
                .frame(width: 83, height: 28)
                .shimmer()
        }
    }

    @ViewBuilder
    private func loadedContent(fiatItem: FiatItem) -> some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text(Localization.onrampYouWillPayTitle)
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)

                textView
            }

            tokenIconView(fiatItem: fiatItem)
        }
    }

    @ViewBuilder
    private func tokenIconView(fiatItem: FiatItem) -> some View {
        Button(action: viewModel.onChangeCurrencyTap) {
            HStack(spacing: 4) {
                IconView(
                    url: fiatItem.iconURL,
                    size: CGSize(width: 20, height: 20),
                    // Kingfisher shows a gray background even if it has a cached image
                    forceKingfisher: false
                )

                Text(fiatItem.currencyCode)
                    .style(Fonts.Bold.footnote, color: Colors.Text.primary1)

                Assets.Glyphs.chevronDownNew.image
                    .foregroundStyle(Colors.Icon.informative)
                    .frame(width: 15, height: 20)
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 6)
            .background(Capsule().fill(Colors.Button.secondary))
        }
        .accessibilityIdentifier(OnrampAccessibilityIdentifiers.currencySelectorButton)
    }

    private var textView: some View {
        VStack(spacing: 4) {
            SendDecimalNumberTextField(viewModel: viewModel.decimalNumberTextFieldViewModel)
                .appearance(.init(font: Fonts.Regular.largeTitle.weight(.semibold)))
                .alignment(.center)
                .prefixSuffixOptions(viewModel.currentFieldOptions)
                .minTextScale(SendAmountStep.Constants.amountMinTextScale)
                .accessibilityIdentifier(OnrampAccessibilityIdentifiers.amountInputField)

            LoadableTextView(
                state: viewModel.bottomInfoText.state,
                font: viewModel.bottomInfoText.isError ? Fonts.Regular.caption1 : Fonts.Bold.subheadline,
                textColor: viewModel.bottomInfoText.isError ? Colors.Text.warning : Colors.Text.secondary,
                loaderSize: CGSize(width: 80, height: 18),
                lineLimit: 2
            )
            .padding(.vertical, viewModel.bottomInfoText.isError ? 2 : 0)
            .multilineTextAlignment(.center)
            .accessibilityIdentifier(OnrampAccessibilityIdentifiers.cryptoAmountLabel)
        }
    }
}
