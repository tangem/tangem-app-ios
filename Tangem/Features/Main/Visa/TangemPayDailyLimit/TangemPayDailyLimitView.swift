//
//  TangemPayDailyLimitView.swift
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
import TangemAccessibilityIdentifiers

struct TangemPayDailyLimitView: View {
    @ObservedObject var viewModel: TangemPayDailyLimitViewModel
    @FocusState private var isInputFocused: Bool

    var body: some View {
        redesignedBody
    }
}

// MARK: - Redesigned

private extension TangemPayDailyLimitView {
    var redesignedBody: some View {
        NavigationStack {
            Group {
                switch viewModel.state {
                case .editLimit:
                    redesignedEditLimitView
                        .focused($isInputFocused)
                        .onAppear { isInputFocused = true }
                case .success:
                    redesignedSuccessView
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    if viewModel.isEditingLimit {
                        Text(Localization.tangempayCardPageDailyLimitTitle)
                            .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
                    }
                }

                if viewModel.isEditingLimit {
                    NavigationToolbarButton.back(placement: .topBarLeading, action: viewModel.close)
                }
            }
            .toolbar(viewModel.isEditingLimit ? .visible : .hidden, for: .navigationBar)
            .bindAlert($viewModel.alert)
            .onAppear {
                viewModel.onAppear()
            }
        }
    }

    var redesignedEditLimitView: some View {
        VStack(spacing: 0) {
            redesignedAmountSection

            Spacer()

            VStack(spacing: 12) {
                redesignedPresetsRow
                    .padding(.horizontal, 12)

                TangemButtonV2(
                    label: AttributedString(Localization.tangempayDailyLimitSetButton),
                    accessibilityLabel: Localization.tangempayDailyLimitSetButton,
                    action: viewModel.submit
                )
                .size(.x12)
                .styleType(.default)
                .horizontalLayout(.infinity)
                .isLoading(viewModel.isLoading)
                .disabled(!viewModel.isSubmitEnabled)
                .accessibilityIdentifier(TangemPayAccessibilityIdentifiers.dailyLimitSetButton)
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystem.Color.bgSecondary.ignoresSafeArea())
    }

    var redesignedAmountSection: some View {
        VStack(spacing: 12) {
            Text(viewModel.hintText)
                .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textTertiary)

            SendDecimalNumberTextField(viewModel: viewModel.amountFieldViewModel)
                .prefixSuffixOptions(.prefix(text: AppConstants.usdSign, hasSpace: false))
                .appearance(.init(
                    font: DesignSystem.Font.displayMediumToken.font,
                    textColor: DesignSystem.Color.textPrimary,
                    placeholderColor: DesignSystem.Color.textTertiary
                ))
                .alignment(.center)
                .accessibilityIdentifier(TangemPayAccessibilityIdentifiers.dailyLimitAmountField)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 32)
        .frame(maxWidth: .infinity)
    }

    var redesignedPresetsRow: some View {
        HStack(spacing: 8) {
            ForEach(viewModel.presets, id: \.self) { preset in
                Button {
                    viewModel.selectPreset(preset)
                } label: {
                    Text(preset)
                        .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(DesignSystem.Color.bgTertiary)
                        .cornerRadiusContinuous(16)
                }
                .accessibilityIdentifier(TangemPayAccessibilityIdentifiers.dailyLimitPresetButton(preset.filter(\.isNumber)))
            }
        }
    }

    var redesignedSuccessView: some View {
        TangemPaySuccessView(
            model: .init(
                icon: DesignSystem.Icons.Success.regular20,
                title: Localization.tangempayCardPageDailyLimitSuccessTitle,
                subtitle: Localization.tangempayCardPageDailyLimitSuccessDescription,
                buttonTitle: Localization.commonDone,
                titleAccessibilityIdentifier: TangemPayAccessibilityIdentifiers.dailyLimitSuccessTitle,
                buttonAccessibilityIdentifier: TangemPayAccessibilityIdentifiers.dailyLimitDoneButton
            ),
            action: viewModel.close
        )
    }
}
