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
        redesignedBody
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
                    .accessibilityIdentifier(TangemPayAccessibilityIdentifiers.pinScreenTitle)

                TangemPayPinStackView(
                    pinText: $viewModel.pin,
                    length: viewModel.pinCodeLength,
                    errorMessage: viewModel.errorMessage,
                    isDisabled: viewModel.isLoading
                )
                .accessibilityIdentifier(TangemPayAccessibilityIdentifiers.pinInputField)

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
                buttonTitle: Localization.commonClose,
                titleAccessibilityIdentifier: TangemPayAccessibilityIdentifiers.pinSuccessTitle,
                buttonAccessibilityIdentifier: TangemPayAccessibilityIdentifiers.pinDoneButton
            ),
            action: viewModel.close
        )
    }
}
