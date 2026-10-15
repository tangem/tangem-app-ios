//
//  PromoCampaignPrecheckView.swift
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

struct PromoCampaignPrecheckView: View {
    let viewModel: PromoCampaignPrecheckViewModel

    var body: some View {
        VStack(spacing: Constants.sectionSpacing) {
            header

            if let payoutWallet = viewModel.payoutWallet, let payout = payoutWallet.payout {
                PromoCampaignPayoutCardView(walletName: payoutWallet.name, imageProvider: payoutWallet.imageProvider, payout: payout)
            }

            TangemUI.Button(label: Localization.commonClose, accessibilityLabel: nil, action: viewModel.close)
                .styleType(.primary)
                .horizontalLayout(.infinity)
                .size(.x12)
        }
        .padding(.horizontal, 16)
        .padding(.top, Constants.topPadding)
        .padding(.bottom, 8)
        .overlay(alignment: .topTrailing) {
            NavigationBarButton.close(action: viewModel.close)
                .padding(16)
        }
        .floatingSheetConfiguration { configuration in
            configuration.sheetBackgroundColor = DesignSystem.Color.bgPrimary
            configuration.backgroundInteractionBehavior = .tapToDismiss
        }
    }

    private var header: some View {
        VStack(spacing: Constants.headerSpacing) {
            viewModel.icon.image
                .resizable()
                .frame(width: Constants.iconSide, height: Constants.iconSide)
                .foregroundStyle(viewModel.iconColor)
                .frame(width: Constants.iconCircleSide, height: Constants.iconCircleSide)
                .background(viewModel.iconBackgroundColor)
                .clipShape(Circle())
                .accessibilityHidden(true)

            VStack(spacing: 8) {
                Text(viewModel.title)
                    .style(DesignSystem.Font.headingSmallToken, color: DesignSystem.Color.textPrimary)
                    .accessibilityAddTraits(.isHeader)

                if let subtitle = viewModel.subtitle {
                    Text(subtitle)
                        .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                }
            }
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, Constants.headerBottomPadding)
    }
}

// MARK: - Constants

private enum Constants {
    static let topPadding: CGFloat = 64
    static let sectionSpacing: CGFloat = 16
    static let headerSpacing: CGFloat = 24
    static let headerBottomPadding: CGFloat = 16
    static let iconSide: CGFloat = 28
    static let iconCircleSide: CGFloat = 68
}

// MARK: - Previews

#Preview("Already enrolled, one wallet") {
    PromoCampaignPrecheckView(viewModel: PromoCampaignPrecheckViewModel(
        state: .alreadyEnrolled(campaignName: "Whale Swap Cashback", wallets: [PromoCampaignEnrollmentWallet.previewWallets[0]]),
        coordinator: nil
    ))
    .background(DesignSystem.Color.bgPrimary)
}

#Preview("Already enrolled, several wallets") {
    PromoCampaignPrecheckView(viewModel: PromoCampaignPrecheckViewModel(
        state: .alreadyEnrolled(campaignName: "Whale Swap Cashback", wallets: PromoCampaignEnrollmentWallet.previewWallets),
        coordinator: nil
    ))
    .background(DesignSystem.Color.bgPrimary)
}

#Preview("Campaign unavailable") {
    PromoCampaignPrecheckView(viewModel: PromoCampaignPrecheckViewModel(state: .campaignUnavailable, coordinator: nil))
        .background(DesignSystem.Color.bgPrimary)
}

#Preview("Campaign not available yet") {
    PromoCampaignPrecheckView(viewModel: PromoCampaignPrecheckViewModel(state: .temporarilyUnavailable, coordinator: nil))
        .background(DesignSystem.Color.bgPrimary)
}
