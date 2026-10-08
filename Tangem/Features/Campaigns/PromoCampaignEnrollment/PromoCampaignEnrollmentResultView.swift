//
//  PromoCampaignEnrollmentResultView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct PromoCampaignEnrollmentResultView: View {
    let viewModel: PromoCampaignEnrollmentResultViewModel

    var body: some View {
        if let payoutWallet = viewModel.payoutWallet, let payout = payoutWallet.payout {
            screen.details {
                PromoCampaignPayoutCardView(walletName: payoutWallet.name, imageProvider: payoutWallet.imageProvider, payout: payout)
            }
        } else if !viewModel.enrolledWallets.isEmpty {
            screen.details {
                PromoCampaignEnrolledWalletsView(wallets: viewModel.enrolledWallets)
            }
        } else {
            screen
        }
    }

    private var screen: StatusScreen<EmptyView, EmptyView, EmptyView> {
        StatusScreen(
            title: viewModel.title,
            description: viewModel.description,
            actionTitle: viewModel.actionTitle,
            action: viewModel.performAction
        )
        .appearance(viewModel.appearance)
    }
}

// MARK: - Previews

#Preview("Enrolled, one wallet") {
    PromoCampaignEnrollmentResultView(viewModel: .preview(.enrolled(campaignName: "Whale Swap Cashback", walletCount: 1)))
}

#Preview("Enrolled, several wallets") {
    PromoCampaignEnrollmentResultView(viewModel: .preview(.enrolled(campaignName: "Whale Swap Cashback", walletCount: 2)))
}

#Preview("Already enrolled, one wallet") {
    PromoCampaignEnrollmentResultView(viewModel: .preview(
        .alreadyEnrolled(campaignName: "Whale Swap Cashback", wallets: [PromoCampaignEnrollmentWallet.previewWallets[0]])
    ))
}

#Preview("Already enrolled, several wallets") {
    PromoCampaignEnrollmentResultView(viewModel: .preview(
        .alreadyEnrolled(campaignName: "Whale Swap Cashback", wallets: PromoCampaignEnrollmentWallet.previewWallets)
    ))
}

#Preview("Partially enrolled") {
    PromoCampaignEnrollmentResultView(viewModel: .preview(
        .partiallyEnrolled(campaignName: "Whale Swap Cashback", enrolledWallets: PromoCampaignEnrollmentWallet.previewWallets)
    ))
}

#Preview("Campaign unavailable") {
    PromoCampaignEnrollmentResultView(viewModel: .preview(.campaignUnavailable))
}

#Preview("Temporarily unavailable") {
    PromoCampaignEnrollmentResultView(viewModel: .preview(.temporarilyUnavailable))
}

#Preview("Failed") {
    PromoCampaignEnrollmentResultView(viewModel: .preview(.failed))
}

private extension PromoCampaignEnrollmentResultViewModel {
    static func preview(_ state: State) -> PromoCampaignEnrollmentResultViewModel {
        PromoCampaignEnrollmentResultViewModel(state: state, coordinator: nil)
    }
}
