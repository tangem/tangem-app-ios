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
        content
    }
}

private extension TangemPayPinView {
    var content: some View {
        NavigationStack {
            Group {
                switch viewModel.state {
                case .enterPin:
                    enterPinView
                case .created:
                    successView
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

    var enterPinView: some View {
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
                    Loader()
                        .loaderSize(.size24)
                }
            }
            .padding(.top, 64)
            .padding(.horizontal, 24)

            Spacer()
        }
        .screenCaptureProtection()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
        .onAppear(perform: viewModel.onAppear)
    }

    var successView: some View {
        StatusScreen(
            title: Localization.tangempayCardDetailsChangePinSuccessTitle,
            description: Localization.tangempayCardDetailsChangePinSuccessDescription,
            actionTitle: Localization.commonClose,
            action: viewModel.close
        )
        .appearance(.success)
    }
}
