//
//  VisaOnboardingPinView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemUI

struct VisaOnboardingPinView: View {
    @ObservedObject var viewModel: VisaOnboardingPinViewModel

    var body: some View {
        VStack(spacing: 40) {
            VStack(spacing: 10) {
                Text(Localization.visaOnboardingPinCodeTitle)
                    .style(Fonts.Bold.title1, color: Colors.Text.primary1)
                    .multilineTextAlignment(.center)
                    .padding(.top, 32)

                Text(Localization.visaOnboardingPinCodeDescription)
                    .style(Fonts.Regular.callout, color: Colors.Text.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 40)

            VStack(spacing: 4) {
                OnboardingPinStackView(
                    maxDigits: viewModel.pinCodeLength,
                    isDisabled: viewModel.isLoading,
                    pinText: $viewModel.pinCode
                )

                Text(viewModel.errorMessage ?? " ")
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .style(Fonts.Regular.footnote, color: Colors.Text.warning)
                    .hidden(viewModel.errorMessage == nil)
                    .padding(.horizontal, 16)
            }

            Spacer()

            MainButton(
                title: Localization.commonSubmit,
                isLoading: viewModel.isLoading,
                isDisabled: !viewModel.isPinCodeValid,
                action: viewModel.submitPinCodeAction
            )
            .padding(.bottom, 20)
            .padding(.horizontal, 16)
        }
    }
}

#Preview {
    VisaOnboardingPinView(viewModel: .init(delegate: nil))
}
