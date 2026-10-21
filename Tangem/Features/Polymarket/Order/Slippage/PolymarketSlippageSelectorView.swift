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
            amount

            Spacer().frame(height: Constants.amountToPresetsGap)

            presets

            Spacer().frame(height: viewModel.isRedesigned ? Constants.redesignedPresetsToDescriptionGap : Constants.presetsToDescriptionGap)

            if viewModel.isRedesigned {
                hint
            } else {
                description
            }
        }
        .padding(.top, Constants.topPadding)
        .padding(.bottom, Constants.bottomPadding)
        .frame(maxWidth: .infinity)
        .focused($isInputFocused)
        .onAppear { isInputFocused = true }
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
            HStack(spacing: viewModel.isRedesigned ? Constants.redesignedPresetSpacing : Constants.presetSpacing) {
                ForEach(viewModel.presets) { preset in
                    if viewModel.isRedesigned {
                        presetButton(preset)
                    } else {
                        presetChip(preset)
                    }
                }
            }
            .padding(.horizontal, Constants.horizontalPadding)
        }
    }

    private func presetChip(_ preset: PolymarketSlippageSelectorViewModel.Preset) -> some View {
        SwiftUI.Button {
            viewModel.handleViewAction(.selectPreset(preset))
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

    private func presetButton(_ preset: PolymarketSlippageSelectorViewModel.Preset) -> some View {
        TangemUI.Button(
            label: preset.title,
            accessibilityLabel: nil,
            action: { viewModel.handleViewAction(.selectPreset(preset)) }
        )
        .size(.x8)
        .styleType(.secondary(.default))
    }

    private var hint: some View {
        HStack(alignment: .top, spacing: Constants.hintSpacing) {
            DesignSystem.Icons.Percent.regular20.image
                .renderingMode(.template)
                .resizable()
                .frame(width: Constants.hintIconSide, height: Constants.hintIconSide)
                .foregroundStyle(DesignSystem.Color.iconPrimary)

            Text(Localization.predictionPlaceSlippageSheetDescription)
                .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, Constants.hintHorizontalPadding)
        .padding(.vertical, Constants.hintVerticalPadding)
    }

    private var description: some View {
        Text(Localization.predictionPlaceSlippageSheetDescription)
            .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Constants.horizontalPadding)
    }
}

// MARK: - Footer

struct PolymarketSlippageSelectorFooterView: View {
    @ObservedObject private var viewModel: PolymarketSlippageSelectorViewModel

    init(viewModel: PolymarketSlippageSelectorViewModel) {
        _viewModel = ObservedObject(wrappedValue: viewModel)
    }

    var body: some View {
        TangemUI.Button(
            label: Localization.commonConfirm,
            accessibilityLabel: Localization.commonConfirm,
            action: { viewModel.handleViewAction(.confirm) }
        )
        .styleType(.primary)
        .size(.x12)
        .horizontalLayout(.infinity)
        .disabled(!viewModel.isConfirmEnabled)
        .padding(.horizontal, Constants.horizontalPadding)
        .padding(.vertical, Constants.verticalPadding)
    }
}

// MARK: - Constants

private extension PolymarketSlippageSelectorView {
    enum Constants {
        static let topPadding: CGFloat = 40
        static let bottomPadding: CGFloat = 24
        static let amountToPresetsGap: CGFloat = 32
        static let presetsToDescriptionGap: CGFloat = 16
        static let redesignedPresetsToDescriptionGap: CGFloat = 16
        static let redesignedPresetSpacing: CGFloat = 4
        static let hintSpacing: CGFloat = 12
        static let hintIconSide: CGFloat = 20
        static let hintHorizontalPadding: CGFloat = 24
        static let hintVerticalPadding: CGFloat = 12
        static let errorSpacing: CGFloat = 8
        static let presetSpacing: CGFloat = 8
        static let presetHeight: CGFloat = 32
        static let presetHorizontalPadding: CGFloat = 12
        static let horizontalPadding: CGFloat = 16
        static let percentSign = "%"
    }
}

private extension PolymarketSlippageSelectorFooterView {
    enum Constants {
        static let horizontalPadding: CGFloat = 16
        static let verticalPadding: CGFloat = 12
    }
}
