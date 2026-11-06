//
//  OnrampAmountView.swift
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

struct OnrampAmountView: View {
    @ObservedObject var viewModel: OnrampAmountViewModel

    var body: some View {
        content
            .infinityFrame(axis: .horizontal)
            .animation(.easeInOut, value: viewModel.error)
            .padding(.horizontal, 16)
            .padding(.vertical, 32)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(DesignSystem.Color.bgSecondary)
            )
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.fiatItem {
        case .some(let fiatItem):
            loadedContent(fiatItem: fiatItem)
        case .none:
            loadingContent
        }
    }

    private var loadingContent: some View {
        VStack(spacing: 12) {
            Shimmer().variant(.text(style: .subheading, alignment: .center))
                .frame(width: 75)

            Shimmer().variant(.text(style: .display, alignment: .center))
                .frame(width: 140)

            Shimmer().variant(.custom(width: 83, height: 28, cornerRadius: 14))
        }
    }

    private func loadedContent(fiatItem: FiatItem) -> some View {
        VStack(spacing: 12) {
            Text(Localization.onrampYouWillPayTitle)
                .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textSecondary)

            textView

            currencyButton(fiatItem: fiatItem)
        }
    }

    private func currencyButton(fiatItem: FiatItem) -> some View {
        SwiftUI.Button(action: viewModel.onChangeCurrencyTap) {
            HStack(spacing: 0) {
                IconView(
                    url: fiatItem.iconURL,
                    size: CGSize(width: 16, height: 16),
                    // Kingfisher shows a gray background even if it has a cached image
                    forceKingfisher: false
                )
                .clipShape(Circle())

                Text(fiatItem.currencyCode)
                    .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textPrimary)
                    .padding(.horizontal, 4)

                DesignSystem.Icons.ChevronDown.regular16.image
                    .renderingMode(.template)
                    .foregroundStyle(DesignSystem.Color.iconPrimary)
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 6)
            .frame(minWidth: 40, minHeight: 28)
            .background(Capsule().fill(DesignSystem.Color.bgTransparentPrimary))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(OnrampAccessibilityIdentifiers.currencySelectorButton)
    }

    private var textView: some View {
        VStack(spacing: 4) {
            SendDecimalNumberTextField(viewModel: viewModel.decimalNumberTextFieldViewModel)
                .appearance(.init(font: DesignSystem.Font.displayMediumToken.font))
                .alignment(.center)
                .prefixSuffixOptions(viewModel.currentFieldOptions)
                .minTextScale(SendAmountStep.Constants.amountMinTextScale)
                .accessibilityIdentifier(OnrampAccessibilityIdentifiers.amountInputField)
                .prefixSuffixAccessibilityIdentifier(OnrampAccessibilityIdentifiers.currencySymbolPrefix)

            errorView
        }
    }

    @ViewBuilder
    private var errorView: some View {
        if let error = viewModel.error {
            Text(error)
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textStatusError)
                .lineLimit(2)
                .padding(.vertical, 2)
                .multilineTextAlignment(.center)
        }
    }
}
