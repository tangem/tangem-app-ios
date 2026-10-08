//
//  PromoCampaignEnrolledWalletsView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI
import TangemUIUtils

struct PromoCampaignEnrolledWalletsView: View {
    let wallets: [PromoCampaignEnrollmentWallet]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(Localization.promoCampaignEnrolledWallets)
                .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
                .padding(.vertical, 12)
                .accessibilityAddTraits(.isHeader)

            ScrollView {
                VStack(spacing: 0) {
                    ForEach(Array(wallets.enumerated()), id: \.offset) { _, wallet in
                        TangemUI.Row(title: wallet.name, subtitle: wallet.subtitle)
                            .start {
                                PromoCampaignWalletImageView(imageProvider: wallet.imageProvider, side: Constants.walletImageSide)
                            }
                    }
                }
                .padding(.vertical, 8)
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollIndicators(.hidden)
            .frame(maxHeight: Constants.listMaxHeight)
            .background(DesignSystem.Color.bgTransparentPrimary)
            .cornerRadiusContinuous(Constants.cornerRadius)
        }
    }
}

// MARK: - Constants

private enum Constants {
    static let cornerRadius: CGFloat = 20
    static let walletImageSide: CGFloat = 36
    static let listMaxHeight: CGFloat = 280
}

// MARK: - Previews

#Preview {
    PromoCampaignEnrolledWalletsView(wallets: PromoCampaignEnrollmentWallet.previewWallets)
        .padding(16)
        .background(DesignSystem.Color.bgPrimary)
}

extension PromoCampaignEnrollmentWallet {
    static let previewWallets: [PromoCampaignEnrollmentWallet] = [
        PromoCampaignEnrollmentWallet(
            name: "Main wallet",
            subtitle: "3 cards • $4,496.75",
            imageProvider: CardImageProviderMock(),
            payout: Payout(
                address: "0x33Bd321fS9a0c4e1b7d2E5f8a6C3b0xxdSga21412B"
            )
        ),
        PromoCampaignEnrollmentWallet(
            name: "Multi Card",
            subtitle: "1 card • $0.03",
            imageProvider: CardImageProviderMock(),
            payout: nil
        ),
    ]
}
