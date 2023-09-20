//
//  GenerateAddressesView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct GenerateAddressesView: View {
    let numberOfNetworks: Int
    let currentWalletNumber: Int
    let totalWalletNumber: Int
    let didTapGenerate: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Colors.Icon.accent
                    .frame(size: CGSize(bothDimensions: 36))
                    .clipShape(Circle())
                    .opacity(0.12)
                    .overlay(Assets.blueCircleWarning.image)

                VStack(alignment: .leading, spacing: 2) {
                    Text(Localization.mainWarningMissingDerivationTitle)
                        .style(Fonts.Bold.footnote, color: Colors.Text.primary1)

                    Text(Localization.mainWarningMissingDerivationDescription(numberOfNetworks))
                        .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
                }
            }

            MainButton(
                title: Localization.commonGenerateAddresses,
                subtitle: Localization.manageTokensNumberOfWallets(currentWalletNumber, totalWalletNumber),
                icon: .trailing(Assets.tangemIcon),
                style: .primary,
                action: didTapGenerate
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .padding(.bottom, UIApplication.safeAreaInsets.bottom)
        .background(Colors.Background.action.ignoresSafeArea())
        .cornerRadius(24, corners: [.topLeft, .topRight])
        .offset(y: UIApplication.safeAreaInsets.bottom)
        .shadow(color: .black.opacity(0.12), radius: 32, x: 0, y: -5)
    }
}

struct GenerateAddressesView_Previews: PreviewProvider {
    static var previews: some View {
        Colors.Background.primary.ignoresSafeArea()
            .overlay(GenerateAddressesView(numberOfNetworks: 3, currentWalletNumber: 1, totalWalletNumber: 2, didTapGenerate: {}), alignment: .bottom)
    }
}
