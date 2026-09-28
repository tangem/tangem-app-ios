//
//  OnboardingSeedPassphraseSetupView.swift
//  Tangem
//
//  Created by Dean Rie on 28.09.2026.
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemUI

struct OnboardingSeedPassphraseSetupView: View {
    @ObservedObject var viewModel: OnboardingSeedPassphraseSetupViewModel

    var body: some View {
        VStack(spacing: 12) {
            toggleRow

            if viewModel.isEnabled {
                warningBanner

                passphraseField(
                    text: $viewModel.passphrase,
                    isResponder: $viewModel.isPassphraseInputResponder,
                    placeholder: Localization.commonPassphrase
                )

                passphraseField(
                    text: $viewModel.confirmation,
                    isResponder: $viewModel.isConfirmationInputResponder,
                    placeholder: Localization.onboardingSeedPassphraseSetupConfirmPlaceholder
                )

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .style(Fonts.Regular.footnote, color: Colors.Text.warning)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 14)
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.isEnabled)
        .bottomSheet(
            item: $viewModel.infoBottomSheetModel,
            backgroundColor: Colors.Background.primary
        ) { model in
            OnboardingSeedPassphraseInfoBottomSheetView(model: model)
        }
    }

    private var toggleRow: some View {
        HStack(spacing: 0) {
            Text(Localization.onboardingSeedPassphraseSetupToggle)
                .style(Fonts.Regular.callout, color: Colors.Text.primary1)

            SwiftUI.Button(action: viewModel.openInfo) {
                Assets.infoCircle20.image
                    .foregroundStyle(Colors.Icon.informative)
                    .padding(.horizontal, 4)
            }

            Spacer(minLength: 8)

            Toggle("", isOn: $viewModel.isEnabled)
                .labelsHidden()
                .tint(Colors.Control.checked)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Colors.Field.primary)
        .cornerRadiusContinuous(14)
    }

    private var warningBanner: some View {
        var message = Localization.onboardingSeedPassphraseSetupWarningMessage
        if viewModel.showsMobileUpgradeNote {
            message += "\n\n" + Localization.onboardingSeedPassphraseSetupMobileUpgradeNote
        }

        return MessageBanner(
            title: Localization.onboardingSeedPassphraseSetupWarningTitle,
            description: message
        )
        .variant(.warning)
    }

    private func passphraseField(text: Binding<String>, isResponder: Binding<Bool?>, placeholder: String) -> some View {
        CustomTextField(
            text: text,
            isResponder: isResponder,
            actionButtonTapped: .constant(true),
            handleKeyboard: false,
            keyboard: .asciiCapable,
            clearButtonMode: .whileEditing,
            placeholder: placeholder
        )
        .setAutocapitalizationType(.none)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Colors.Field.primary)
        .cornerRadiusContinuous(14)
        .screenCaptureProtection()
    }
}

#Preview {
    let viewModel = OnboardingSeedPassphraseSetupViewModel(showsMobileUpgradeNote: true)
    viewModel.isEnabled = true

    return OnboardingSeedPassphraseSetupView(viewModel: viewModel)
        .padding(16)
}
