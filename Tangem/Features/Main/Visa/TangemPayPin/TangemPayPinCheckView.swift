//
//  TangemPayPinCheckView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemUI
import TangemUIUtils
import TangemAssets
import TangemAccessibilityIdentifiers

struct TangemPayPinCheckView: View {
    @ObservedObject var viewModel: TangemPayPinCheckViewModel

    var body: some View {
        content
    }
}

private extension TangemPayPinCheckView {
    var content: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Spacer(minLength: 0)

                TangemUI.Button(
                    icon: DesignSystem.Icons.Cross.regular20,
                    accessibilityLabel: Localization.commonClose,
                    action: viewModel.close
                )
                .size(.x11)
                .styleType(.material(.glass))
            }
            .padding(.top, 16)
            .padding(.horizontal, 16)

            VStack(spacing: 32) {
                VStack(spacing: 8) {
                    Text(Localization.tangempayYourPinCode)
                        .style(DesignSystem.Font.headingSmallToken, color: DesignSystem.Color.textPrimary)
                        .accessibilityIdentifier(TangemPayAccessibilityIdentifiers.pinCheckTitle)

                    Text(Localization.tangempayComeBackIfForgetPin)
                        .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textSecondary)
                }
                .multilineTextAlignment(.center)

                pinContent
            }
            .padding(.top, 32)
            .padding(.horizontal, 16)

            changePinButton
        }
        .frame(maxWidth: .infinity)
    }

    var pinContent: some View {
        Color.clear
            .frame(height: 64)
            .overlay {
                switch viewModel.state {
                case .loading:
                    Loader()
                        .loaderSize(.size24)
                        .accessibilityIdentifier(TangemPayAccessibilityIdentifiers.pinCheckLoader)

                case .loaded(let pin):
                    TangemPayPinStackView(
                        pinText: .constant(pin),
                        length: viewModel.pinCodeLength,
                        isDisabled: true
                    )
                    .screenCaptureProtection()
                    .accessibilityIdentifier(TangemPayAccessibilityIdentifiers.pinCheckValue)
                }
            }
    }

    var changePinButton: some View {
        TangemUI.Button(
            label: AttributedString(Localization.tangempayChangePinCode),
            accessibilityLabel: Localization.tangempayChangePinCode,
            action: viewModel.changePin
        )
        .size(.x12)
        .styleType(.primary)
        .horizontalLayout(.infinity)
        .disabled(!viewModel.isPinLoaded)
        .accessibilityIdentifier(TangemPayAccessibilityIdentifiers.pinCheckChangeButton)
        .padding(.top, 32)
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
}
