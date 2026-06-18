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

struct TangemPayDailyLimitView: View {
    @ObservedObject var viewModel: TangemPayDailyLimitViewModel
    @FocusState private var isInputFocused: Bool

    var body: some View {
        if FeatureProvider.isAvailable(.tangemPaySpendRedesign) {
            redesignedBody
        } else {
            legacyBody
        }
    }

    private var legacyBody: some View {
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
                    if viewModel.state == .editLimit {
                        Text(Localization.tangempayCardPageDailyLimitTitle)
                            .style(Fonts.Bold.body, color: Colors.Text.primary1)
                    }
                }
            }
            .toolbar {
                if viewModel.state == .editLimit {
                    NavigationToolbarButton.close(
                        placement: .topBarTrailing,
                        action: viewModel.close
                    )
                }
            }
            .bindAlert($viewModel.alert)
            .onAppear {
                viewModel.onAppear()
            }
        }
    }

    private var editLimitView: some View {
        VStack(spacing: 0) {
            amountSection

            Spacer()

            VStack(spacing: 22) {
                MainButton(
                    title: Localization.tangempayDailyLimitSetButton,
                    isLoading: viewModel.isLoading,
                    isDisabled: !viewModel.isSubmitEnabled,
                    action: viewModel.submit
                )

                presetsRow
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
        .background(Colors.Background.tertiary.ignoresSafeArea())
    }

    private var amountSection: some View {
        VStack(spacing: 12) {
            Text(Localization.commonAmount)
                .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

            VStack(spacing: 8) {
                SendDecimalNumberTextField(viewModel: viewModel.amountFieldViewModel)
                    .prefixSuffixOptions(.prefix(text: AppConstants.usdSign, hasSpace: false))
                    .appearance(.init(font: Fonts.Regular.largeTitle.weight(.semibold)))
                    .alignment(.center)

                Text(viewModel.hintText)
                    .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
                    .padding(.vertical, 2)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 56)
        .frame(maxWidth: .infinity)
        .background(Colors.Background.primary)
        .cornerRadiusContinuous(14)
        .padding(.horizontal, 16)
    }

    private var presetsRow: some View {
        HStack(spacing: 8) {
            ForEach(viewModel.presets, id: \.self) { preset in
                Button {
                    viewModel.selectPreset(preset)
                } label: {
                    Text(preset)
                        .style(Fonts.Bold.footnote, color: Colors.Text.primary1)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 5)
                        .background(Colors.Button.secondary)
                        .cornerRadiusContinuous(14)
                }
            }
        }
    }

    // MARK: - Success

    @ViewBuilder
    private var successView: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 20) {
                Assets.Visa.success.image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 76, height: 76)

                VStack(spacing: 12) {
                    Text(Localization.tangempayCardPageDailyLimitSuccessTitle)
                        .style(Fonts.Bold.title1, color: Colors.Text.primary1)
                        .multilineTextAlignment(.center)

                    Text(Localization.tangempayCardPageDailyLimitSuccessDescription)
                        .style(Fonts.Regular.callout, color: Colors.Text.secondary)
                        .multilineTextAlignment(.center)
                }
            }

            Spacer()

            MainButton(
                title: Localization.commonDone,
                action: viewModel.close
            )
            .padding(.bottom, 20)
            .padding(.horizontal, 16)
        }
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
            }
        }
    }

    var redesignedSuccessView: some View {
        TangemPaySuccessView(
            model: .init(
                icon: DesignSystem.Icons.Success.regular20,
                title: Localization.tangempayCardPageDailyLimitSuccessTitle,
                subtitle: Localization.tangempayCardPageDailyLimitSuccessDescription,
                buttonTitle: Localization.commonDone
            ),
            action: viewModel.close
        )
    }
}
