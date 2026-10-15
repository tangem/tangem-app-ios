//
//  SwapSlippageSelectorView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI
import TangemUIUtils

struct SwapSlippageSelectorView: View {
    @ObservedObject var viewModel: SwapSlippageSelectorViewModel

    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(spacing: .zero) {
            BottomSheetHeaderView(
                title: Localization.commonSlippage,
                trailing: { NavigationBarButton.close(action: viewModel.dismiss) }
            )
            .padding(.horizontal, Constants.horizontalPadding)

            content

            hints

            MainButton(
                title: Localization.commonConfirm,
                isDisabled: !viewModel.isConfirmEnabled,
                action: viewModel.confirm
            )
            .padding(.horizontal, Constants.horizontalPadding)
            .padding(.vertical, Constants.confirmVerticalPadding)
        }
        .floatingSheetConfiguration { configuration in
            configuration.backgroundInteractionBehavior = .tapToDismiss
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.content {
        case .customizable(_, let presets):
            VStack(spacing: .zero) {
                amount
                    .padding(.top, Constants.amountTopPadding)
                    .padding(.bottom, Constants.amountBottomPadding)

                presetsView(presets)
            }
            .focused($isInputFocused)
            .onAppear { isInputFocused = true }

        case .notCustomizable(let maxSlippage):
            MessageBanner(title: AttributedString(Localization.swapCustomSlippageInfo(maxSlippage)))
                .variant(.info)
                .glowRing(.info)
                .padding(.horizontal, Constants.horizontalPadding)
                .padding(.vertical, Constants.bannerVerticalPadding)
        }
    }

    private var amount: some View {
        VStack(spacing: Constants.messageSpacing) {
            SendDecimalNumberTextField(viewModel: viewModel.fieldViewModel)
                .prefixSuffixOptions(.suffix(text: Constants.percentSign, hasSpace: false))
                .appearance(.init(
                    font: DesignSystem.Font.displayMediumToken.font,
                    textColor: DesignSystem.Color.textPrimary,
                    placeholderColor: DesignSystem.Color.textTertiary
                ))
                .alignment(.center)

            if let message = viewModel.message {
                messageView(message)
            }
        }
        .padding(.horizontal, Constants.horizontalPadding)
    }

    @ViewBuilder
    private func messageView(_ message: SwapSlippageSelectorViewModel.Message) -> some View {
        switch message {
        case .unsupportedAmount:
            Text(Localization.swapSlippageError)
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textStatusError)
        case .mayFail:
            Text(Localization.swapSlippageWarningText)
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textStatusWarning)
        }
    }

    private func presetsView(_ presets: [SwapSlippageSelectorViewModel.Preset]) -> some View {
        HStack(spacing: Constants.presetSpacing) {
            ForEach(presets) { preset in
                SwiftUI.Button {
                    viewModel.select(preset: preset)
                } label: {
                    Text(preset.title)
                        .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
                        .lineLimit(1)
                        .padding(.horizontal, Constants.presetHorizontalPadding)
                        .frame(minWidth: Constants.presetMinWidth, minHeight: Constants.presetHeight)
                        .background(DesignSystem.Color.bgTransparentPrimary, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, Constants.horizontalPadding)
        .padding(.vertical, Constants.presetsVerticalPadding)
    }

    private var hints: some View {
        VStack(alignment: .leading, spacing: Constants.hintSpacing) {
            hint(icon: Assets.DesignSystem.percent, iconSize: Constants.percentIconSize, title: Localization.commonSlippage, text: Localization.swapSlippageInfoText)

            hint(icon: Assets.DesignSystem.dollar, iconSize: Constants.dollarIconSize, title: Localization.swapExchangeRatesInfoTitle, text: Localization.swapExchangeRatesInfoText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Constants.hintsHorizontalPadding)
        .padding(.top, Constants.hintsTopPadding)
        .padding(.bottom, Constants.hintsBottomPadding)
    }

    private func hint(icon: ImageType, iconSize: CGFloat, title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: Constants.hintIconSpacing) {
            icon.image
                .resizable()
                .renderingMode(.template)
                .foregroundStyle(DesignSystem.Color.iconPrimary)
                .frame(width: iconSize, height: iconSize)

            Text("\(Text(title).foregroundColor(DesignSystem.Color.textPrimary)) \(Text(text).foregroundColor(DesignSystem.Color.textSecondary))")
                .font(DesignSystem.Font.subheadingMediumToken.font)
        }
    }
}

// MARK: - Constants

private extension SwapSlippageSelectorView {
    enum Constants {
        static let horizontalPadding: CGFloat = 16
        static let amountTopPadding: CGFloat = 36
        static let amountBottomPadding: CGFloat = 32
        static let messageSpacing: CGFloat = 8
        static let presetSpacing: CGFloat = 4
        static let presetHeight: CGFloat = 32
        static let presetMinWidth: CGFloat = 48
        static let presetHorizontalPadding: CGFloat = 12
        static let presetsVerticalPadding: CGFloat = 4
        static let bannerVerticalPadding: CGFloat = 12
        static let hintSpacing: CGFloat = 16
        static let hintIconSpacing: CGFloat = 12
        static let hintsHorizontalPadding: CGFloat = 24
        static let hintsTopPadding: CGFloat = 28
        static let hintsBottomPadding: CGFloat = 12
        static let percentIconSize: CGFloat = 20
        static let dollarIconSize: CGFloat = 16
        static let confirmVerticalPadding: CGFloat = 12
        static let percentSign = "%"
    }
}
