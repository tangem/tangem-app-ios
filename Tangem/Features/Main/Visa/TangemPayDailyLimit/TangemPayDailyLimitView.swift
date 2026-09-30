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
        content
    }
}

private extension TangemPayDailyLimitView {
    var content: some View {
        NavigationStack {
            Group {
                switch viewModel.state {
                case .editLimit:
                    editLimitView
                        .focused($isInputFocused)
                        .onAppear { isInputFocused = true }
                case .success:
                    successView
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

    var editLimitView: some View {
        VStack(spacing: 0) {
            amountSection

            Spacer()

            VStack(spacing: 12) {
                presetsRow
                    .padding(.horizontal, 12)

                TangemUI.Button(
                    label: AttributedString(Localization.tangempayDailyLimitSetButton),
                    accessibilityLabel: Localization.tangempayDailyLimitSetButton,
                    action: viewModel.submit
                )
                .size(.x12)
                .styleType(.default)
                .horizontalLayout(.infinity)
                .loading(.spinner(if: viewModel.isLoading))
                .disabled(!viewModel.isSubmitEnabled)
                .accessibilityIdentifier(TangemPayAccessibilityIdentifiers.dailyLimitSetButton)
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystem.Color.bgSecondary.ignoresSafeArea())
    }

    var amountSection: some View {
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

    var presetsRow: some View {
        HStack(spacing: 8) {
            ForEach(viewModel.presets, id: \.self) { preset in
                SwiftUI.Button {
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

    var successView: some View {
        StatusScreen(
            title: Localization.tangempayCardPageDailyLimitSuccessTitle,
            description: Localization.tangempayCardPageDailyLimitSuccessDescription,
            actionTitle: Localization.commonClose,
            action: viewModel.close
        )
        .appearance(.success)
    }
}
