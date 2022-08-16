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
            Spacer()

            VStack(spacing: 14) {
                biometryImage

                newFeatureBadge

                Text("Would you like to keep wallet on this device?")
                    .style(Fonts.Bold.title1, color: Colors.Text.primary1)
                    .multilineTextAlignment(.center)

                Text("Save your Wallet feature allows you to use your wallet with biometric auth without tapping your card to the phone to gain access.")
                    .style(Fonts.Regular.callout, color: Colors.Text.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 39)

            Spacer()

            VStack(spacing: 10) {
                TangemButton(title: "Accept", action: viewModel.accept)
                    .buttonStyle(TangemButtonStyle(colorStyle: .black, layout: .flexibleWidth))

                TangemButton(title: "Decline", action: viewModel.decline)
                    .buttonStyle(TangemButtonStyle(colorStyle: .grayAlt3, layout: .flexibleWidth))

                Text("Keep notice, making a transaction with your funds will still require card tapping.")
                    .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
    }

    private var biometryImage: some View {
        Assets.Biometry.faceId
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
