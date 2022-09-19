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

    #warning("l10n")
    var body: some View {
        VStack(spacing: 0) {
            if viewModel.showButtons {
                HStack {
                    Spacer()

                    Button("Skip", action: viewModel.decline)
                        .foregroundColor(Colors.Text.primary1)
                }
            }

            Spacer()

            VStack(spacing: 0) {
                BiometryLogoImage.image

                FlexibleSpacer(maxHeight: 28)

                Text("Would you like to use Face ID?")
                    .style(Fonts.Bold.title1, color: Colors.Text.primary1)
                    .multilineTextAlignment(.center)

                FlexibleSpacer(maxHeight: 28)

                newFeatureBadge
            }

            Spacer()

            VStack(spacing: 0) {
                FeatureDescriptionView(
                    icon: BiometryLogoImage.image,
                    title: "Access the app",
                    description: "Log into the app and watch your balance without scanning the card"
                )

                FlexibleSpacer(maxHeight: 28)

                FeatureDescriptionView(
                    icon: Assets.lock,
                    title: "Access code",
                    description: "Face ID will be requested instead of the access code for interactions with your wallet"
                )
            }

            Spacer()

            if viewModel.showButtons {
                VStack(spacing: 10) {
                    TangemButton(title: "Allow to link wallet", action: viewModel.accept)
                        .buttonStyle(TangemButtonStyle(colorStyle: .black, layout: .flexibleWidth))

                    Text("Keep notice, making a transaction with your funds will still require card tapping")
                        .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .padding()
    }

    private var newFeatureBadge: some View {
        Text("New feature")
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
