//
//  OnboardingPinView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct OnboardingPinView: View {
    @ObservedObject var viewModel: OnboardingPinViewModel

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

            OnboardingPinStackView(
                maxDigits: viewModel.pinCodeLength,
                isDisabled: viewModel.isLoading,
                pinText: $viewModel.pinCode
            )

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
    OnboardingPinView(viewModel: .init(delegate: nil))
}
