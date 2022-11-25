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

                Text("save_user_wallet_agreement_header".localized(BiometricAuthorizationUtils.biometryType.name))
                    .style(Fonts.Bold.title1, color: Colors.Text.primary1)
                    .multilineTextAlignment(.center)

                FlexibleSpacer(maxHeight: 28)

                if viewModel.isStandalone {
                    newFeatureBadge
                }
            }

            Spacer()

            VStack(spacing: 0) {
                FeatureDescriptionView(
                    icon: BiometryLogoImage.image,
                    title: "save_user_wallet_agreement_access_title".localized,
                    description: "save_user_wallet_agreement_access_description".localized
                )

                FlexibleSpacer(maxHeight: 28)

                FeatureDescriptionView(
                    icon: Assets.lock,
                    title: "save_user_wallet_agreement_code_title".localized,
                    description: "save_user_wallet_agreement_code_description".localized(BiometricAuthorizationUtils.biometryType.name)
                )
            }

            Spacer()

            VStack(spacing: 10) {
                MainButton(text: BiometricAuthorizationUtils.allowButtonTitle, action: viewModel.accept)

                MainButton(text: "save_user_wallet_agreement_dont_allow".localized,
                           style: .secondary,
                           action: viewModel.decline)

                Text("save_user_wallet_agreement_notice".localized)
                    .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
    }

    private var newFeatureBadge: some View {
        Text("save_user_wallet_agreement_new_feature".localized)
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
