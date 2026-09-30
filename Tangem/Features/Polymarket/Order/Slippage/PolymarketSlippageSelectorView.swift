//
//  PolymarketSlippageSelectorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI
import TangemUIUtils

struct PolymarketSlippageSelectorView: View {
    @ObservedObject private var viewModel: PolymarketSlippageSelectorViewModel

    @FocusState private var isInputFocused: Bool

    init(viewModel: PolymarketSlippageSelectorViewModel) {
        _viewModel = ObservedObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 0) {
            title

            Spacer().frame(height: Constants.titleToAmountGap)

            amount

            Spacer().frame(height: Constants.amountToPresetsGap)

            presets

            Spacer().frame(height: Constants.presetsToDescriptionGap)

            description

            Spacer(minLength: Constants.descriptionToConfirmGap)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
        .safeAreaInset(edge: .bottom, spacing: .zero) { confirm }
        .presentationDragIndicator(.visible)
        .focused($isInputFocused)
        .onAppear { isInputFocused = true }
    }

    private var title: some View {
        Text(Localization.predictionPlaceSlippage)
            .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
            .lineLimit(1)
            .frame(height: Constants.toolbarHeight)
            .padding(.top, Constants.titleTopPadding)
    }

    private var amount: some View {
        VStack(spacing: Constants.errorSpacing) {
            SendDecimalNumberTextField(viewModel: viewModel.fieldViewModel)
                .prefixSuffixOptions(.suffix(text: Constants.percentSign, hasSpace: false))
                .appearance(.init(
                    font: DesignSystem.Font.displayMediumToken.font,
                    textColor: DesignSystem.Color.textPrimary,
                    placeholderColor: DesignSystem.Color.textTertiary
                ))
                .alignment(.center)

            if let errorText = viewModel.errorText {
                Text(errorText)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textStatusError)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, Constants.horizontalPadding)
    }

    private var presets: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Constants.presetSpacing) {
                ForEach(viewModel.presets) { preset in
                    presetChip(preset)
                }
            }
            .padding(.horizontal, Constants.horizontalPadding)
        }
    }

    private func presetChip(_ preset: PolymarketSlippageSelectorViewModel.Preset) -> some View {
        SwiftUI.Button {
            viewModel.select(preset: preset)
        } label: {
            Text(preset.title)
                .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
                .lineLimit(1)
                .padding(.horizontal, Constants.presetHorizontalPadding)
                .frame(minHeight: Constants.presetHeight)
                .background(DesignSystem.Color.bgTransparentPrimary, in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private var description: some View {
        Text(Localization.predictionPlaceSlippageSheetDescription)
            .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Constants.horizontalPadding)
    }

    private var confirm: some View {
        TangemUI.Button(
            label: Localization.commonConfirm,
            accessibilityLabel: Localization.commonConfirm,
            action: viewModel.confirm
        )
        .styleType(.default)
        .size(.x12)
        .horizontalLayout(.infinity)
        .disabled(!viewModel.isConfirmEnabled)
        .padding(.horizontal, Constants.confirmHorizontalPadding)
        .padding(.vertical, Constants.confirmVerticalPadding)
    }
}

// MARK: - Constants

private extension PolymarketSlippageSelectorView {
    enum Constants {
        static let titleTopPadding: CGFloat = 16
        static let toolbarHeight: CGFloat = 44
        static let titleToAmountGap: CGFloat = 52
        static let amountToPresetsGap: CGFloat = 32
        static let presetsToDescriptionGap: CGFloat = 16
        static let descriptionToConfirmGap: CGFloat = 24
        static let errorSpacing: CGFloat = 8
        static let presetSpacing: CGFloat = 8
        static let presetHeight: CGFloat = 32
        static let presetHorizontalPadding: CGFloat = 12
        static let horizontalPadding: CGFloat = 16
        static let confirmHorizontalPadding: CGFloat = 16
        static let confirmVerticalPadding: CGFloat = 12
        static let percentSign = "%"
    }
}
