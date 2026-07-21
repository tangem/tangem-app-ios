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

struct TangemPayPinCheckView: View {
    @ObservedObject var viewModel: TangemPayPinCheckViewModel

    var body: some View {
        redesignedBody
    }
}

// MARK: - Redesigned

private extension TangemPayPinCheckView {
    var redesignedBody: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Spacer(minLength: 0)

                TangemButtonV2(
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

                    Text(Localization.tangempayComeBackIfForgetPin)
                        .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textSecondary)
                }
                .multilineTextAlignment(.center)

                redesignedPinContent
            }
            .padding(.top, 32)
            .padding(.horizontal, 16)

            redesignedChangePinButton
        }
        .frame(maxWidth: .infinity)
        .floatingSheetConfiguration { configuration in
            configuration.sheetBackgroundColor = DesignSystem.Color.bgSecondary
            configuration.backgroundInteractionBehavior = .tapToDismiss
        }
    }

    var redesignedPinContent: some View {
        Color.clear
            .frame(height: 64)
            .overlay {
                switch viewModel.state {
                case .loading:
                    TangemLoader()
                        .loaderSize(.size24)

                case .loaded(let pin):
                    TangemPayPinStackView(
                        pinText: .constant(pin),
                        length: viewModel.pinCodeLength,
                        isDisabled: true
                    )
                }
            }
    }

    var redesignedChangePinButton: some View {
        TangemButtonV2(
            label: AttributedString(Localization.tangempayChangePinCode),
            accessibilityLabel: Localization.tangempayChangePinCode,
            action: viewModel.changePin
        )
        .size(.x12)
        .styleType(.default)
        .horizontalLayout(.infinity)
        .disabled(!viewModel.isPinLoaded)
        .padding(.top, 32)
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
}
