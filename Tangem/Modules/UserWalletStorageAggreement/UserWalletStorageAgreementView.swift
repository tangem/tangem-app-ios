//
//  UserWalletStorageAgreementView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct UserWalletStorageAgreementView: View {
    @ObservedObject private var viewModel: UserWalletStorageAgreementViewModel

    init(viewModel: UserWalletStorageAgreementViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 0) {
                BiometryLogoImage.image.image
                    .renderingMode(.template)
                    .foregroundColor(Colors.Icon.inactive)

                FixedSpacer(height: 28.0)

                Text(Localization.saveUserWalletAgreementHeader(BiometricAuthorizationUtils.biometryType.name))
                    .style(Fonts.Bold.title1, color: Colors.Text.primary1)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                FixedSpacer(height: 28.0)
            }

            Spacer()

            VStack(spacing: 0) {
                OnboardingFeatureDescriptionView(
                    icon: BiometryLogoImage.image,
                    title: Localization.saveUserWalletAgreementAccessTitle,
                    description: Localization.saveUserWalletAgreementAccessDescription
                )

                FixedSpacer(height: 28.0)

                OnboardingFeatureDescriptionView(
                    icon: Assets.lock,
                    title: Localization.saveUserWalletAgreementCodeTitle,
                    description: Localization.saveUserWalletAgreementCodeDescription(BiometricAuthorizationUtils.biometryType.name)
                )
            }

            Spacer()

            VStack(spacing: 10) {
                MainButton(title: BiometricAuthorizationUtils.allowButtonTitle, action: viewModel.accept)

                MainButton(
                    title: Localization.saveUserWalletAgreementDontAllow,
                    style: .secondary,
                    action: viewModel.decline
                )

                Text(Localization.saveUserWalletAgreementNotice)
                    .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
    }
}
