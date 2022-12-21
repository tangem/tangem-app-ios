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
                BiometryLogoImage.image

                FlexibleSpacer(maxHeight: 28)

                Text(L10n.saveUserWalletAgreementHeader(BiometricAuthorizationUtils.biometryType.name))
                    .style(Fonts.Bold.title1, color: Colors.Text.primary1)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                FlexibleSpacer(maxHeight: 28)

                if viewModel.isStandalone {
                    newFeatureBadge
                }
            }

            Spacer()

            VStack(spacing: 0) {
                FeatureDescriptionView(
                    icon: BiometryLogoImage.image,
                    title: L10n.saveUserWalletAgreementAccessTitle,
                    description: L10n.saveUserWalletAgreementAccessDescription
                )

                FlexibleSpacer(maxHeight: 28)

                FeatureDescriptionView(
                    icon: Assets.lock,
                    title: L10n.saveUserWalletAgreementCodeTitle,
                    description: L10n.saveUserWalletAgreementCodeDescription(BiometricAuthorizationUtils.biometryType.name)
                )
            }

            Spacer()

            VStack(spacing: 10) {
                MainButton(title: BiometricAuthorizationUtils.allowButtonLocalizationKey, action: viewModel.accept)

                MainButton(title: L10n.saveUserWalletAgreementDontAllow,
                           style: .secondary,
                           action: viewModel.decline)

                Text(L10n.saveUserWalletAgreementNotice)
                    .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
    }

    private var newFeatureBadge: some View {
        Text(L10n.saveUserWalletAgreementNewFeature)
            .style(Fonts.Bold.caption1, color: Colors.Text.accent)
            .padding(.vertical, 4)
            .padding(.horizontal, 10)
            .background(Colors.Text.accent.opacity(0.12))
            .cornerRadius(8)
    }
}

fileprivate extension UserWalletStorageAgreementView {
    struct FlexibleSpacer: View {
        let maxHeight: CGFloat

        var body: some View {
            Spacer()
                .frame(maxHeight: maxHeight)
        }
    }

    struct FeatureDescriptionView: View {
        let icon: Image
        let title: String
        let description: String

        private let iconSize: Double = 42

        var body: some View {
            HStack(spacing: 16) {
                Colors.Background.secondary
                    .frame(width: iconSize, height: iconSize)
                    .cornerRadius(iconSize / 2)
                    .overlay(
                        icon
                            .resizable()
                            .renderingMode(.template)
                            .foregroundColor(Colors.Text.primary1)
                            .padding(.all, 11)
                    )

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .style(Fonts.Bold.callout, color: Colors.Text.primary1)

                    Text(description)
                        .style(Fonts.Regular.subheadline, color: Colors.Text.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
        }
    }
}
