//
//  TangemPayPinView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemUI
import TangemAccessibilityIdentifiers

struct TangemPayPinView: View {
    @ObservedObject var viewModel: TangemPayPinViewModel

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
                case .enterPin:
                    enterPinView
                case .created:
                    createdView
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if viewModel.state == .enterPin {
                        Button(action: viewModel.close) {
                            Text(Localization.commonClose)
                                .style(Fonts.Regular.body, color: Colors.Text.primary1)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var enterPinView: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(minHeight: 0)

            VStack(spacing: 40) {
                VStack(spacing: 10) {
                    Text(Localization.tangempaySetPinCode)
                        .style(Fonts.Bold.title1, color: Colors.Text.primary1)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier(TangemPayAccessibilityIdentifiers.pinScreenTitle)

                    Text(Localization.visaOnboardingPinCodeDescription)
                        .style(Fonts.Regular.callout, color: Colors.Text.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier(TangemPayAccessibilityIdentifiers.pinScreenDescription)
                }
                .padding(.horizontal, 40)

                VStack(spacing: 4) {
                    OnboardingPinStackView(
                        maxDigits: viewModel.pinCodeLength,
                        isDisabled: viewModel.isLoading,
                        accessibilityIdentifier: TangemPayAccessibilityIdentifiers.pinInputField,
                        pinText: $viewModel.pin
                    )

                    Text(viewModel.errorMessage ?? " ")
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .style(Fonts.Regular.footnote, color: Colors.Text.warning)
                        .hidden(viewModel.errorMessage == nil)
                        .padding(.horizontal, 16)
                        .accessibilityIdentifier(TangemPayAccessibilityIdentifiers.pinErrorMessage)
                }
            }

            Spacer()
                .frame(minHeight: 0)
            Spacer()
                .frame(minHeight: 0)

            MainButton(
                title: Localization.commonSubmit,
                isLoading: viewModel.isLoading,
                isDisabled: !viewModel.isPinCodeValid,
                action: viewModel.submit
            )
            .padding(.bottom, 20)
            .padding(.horizontal, 16)
            .accessibilityIdentifier(TangemPayAccessibilityIdentifiers.pinSubmitButton)
        }
        .onAppear(perform: viewModel.onAppear)
    }

    @ViewBuilder
    private var createdView: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(minHeight: 0)

            VStack(spacing: 20) {
                Assets.Visa.success.image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 76, height: 76)

                VStack(spacing: 12) {
                    Text(Localization.tangempayCardDetailsChangePinSuccessTitle)
                        .style(Fonts.Bold.title1, color: Colors.Text.primary1)
                        .multilineTextAlignment(.center)
                        .accessibilityIdentifier(TangemPayAccessibilityIdentifiers.pinSuccessTitle)

                    Text(Localization.tangempayCardDetailsChangePinSuccessDescription)
                        .style(Fonts.Regular.callout, color: Colors.Text.secondary)
                        .multilineTextAlignment(.center)
                        .frame(width: 265)
                        .accessibilityIdentifier(TangemPayAccessibilityIdentifiers.pinSuccessDescription)
                }
            }

            Spacer()
                .frame(minHeight: 0)
            Spacer()
                .frame(minHeight: 0)

            MainButton(
                title: Localization.commonDone,
                action: viewModel.close
            )
            .padding(.bottom, 20)
            .padding(.horizontal, 16)
            .accessibilityIdentifier(TangemPayAccessibilityIdentifiers.pinDoneButton)
        }
    }
}

// MARK: - Redesigned

private extension TangemPayPinView {
    var redesignedBody: some View {
        NavigationStack {
            Group {
                switch viewModel.state {
                case .enterPin:
                    redesignedEnterPinView
                case .created:
                    redesignedSuccessView
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    if viewModel.isEnteringPin {
                        Text(Localization.tangempaySetPinTitle)
                            .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
                    }
                }

                if viewModel.isEnteringPin {
                    NavigationToolbarButton.close(placement: .topBarTrailing, action: viewModel.close)
                }
            }
            .toolbar(viewModel.isEnteringPin ? .visible : .hidden, for: .navigationBar)
        }
    }

    var redesignedEnterPinView: some View {
        VStack(spacing: 0) {
            VStack(spacing: 24) {
                Text(viewModel.enterPinHeader)
                    .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textTertiary)
                    .multilineTextAlignment(.center)

                TangemPayPinStackView(
                    pinText: $viewModel.pin,
                    length: viewModel.pinCodeLength,
                    errorMessage: viewModel.errorMessage,
                    isDisabled: viewModel.isLoading
                )

                if viewModel.isLoading {
                    TangemLoader()
                        .loaderSize(.size24)
                }
            }
            .padding(.top, 64)
            .padding(.horizontal, 24)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
        .onAppear(perform: viewModel.onAppear)
    }

    var redesignedSuccessView: some View {
        TangemPaySuccessView(
            model: .init(
                icon: DesignSystem.Icons.Success.regular20,
                title: Localization.tangempayCardDetailsChangePinSuccessTitle,
                subtitle: Localization.tangempayCardDetailsChangePinSuccessDescription,
                buttonTitle: Localization.commonClose
            ),
            action: viewModel.close
        )
    }
}
