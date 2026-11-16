//
//  PromoCampaignPayoutCardView.swift
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

struct PromoCampaignPayoutCardView: View {
    let walletName: String
    let walletIcon: UserWalletIcon
    let payout: PromoCampaignEnrollmentWallet.Payout

    var body: some View {
        VStack(spacing: 0) {
            TangemUI.Row(title: walletName)
                .titleAccessory {
                    UserWalletIconView(icon: walletIcon, size: Constants.walletImageSide)
                        .accessibilityHidden(true)
                }

            TangemUI.Row(title: payout.address, subtitle: Localization.sendRecipient)
                .lineOrder(.secondaryFirst)
                .truncationModes(RowTruncationModes(title: .middle))
                .start {
                    AddressBlockiesIconView(
                        viewData: AddressIconProvider.makeBlockiesIconViewData(address: payout.address),
                        size: Constants.addressIconSide
                    )
                }
        }
        .background(DesignSystem.Color.bgTransparentPrimary)
        .cornerRadiusContinuous(Constants.cornerRadius)
    }
}

// MARK: - Constants

private enum Constants {
    static let cornerRadius: CGFloat = 24
    static let walletImageSide: CGFloat = 20
    static let addressIconSide: CGFloat = 36
}

// MARK: - Previews

#Preview {
    let wallet = PromoCampaignEnrollmentWallet.previewWallets[0]

    if let payout = wallet.payout {
        PromoCampaignPayoutCardView(walletName: wallet.name, walletIcon: wallet.walletIcon, payout: payout)
            .padding(16)
            .background(DesignSystem.Color.bgPrimary)
    }
}
