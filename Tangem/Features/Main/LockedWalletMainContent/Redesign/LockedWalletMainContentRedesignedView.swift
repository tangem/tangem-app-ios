//
//  LockedWalletMainContentRedesignedView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemUIUtils
import TangemAssets

struct LockedWalletMainContentRedesignedView: View {
    @ObservedObject var viewModel: LockedWalletMainContentViewModel

    var body: some View {
        VStack(spacing: 0) {
            NotificationBannerContainer(
                items: viewModel.notificationBannerItems,
                stackingType: .carousel
            )
            .confirmationDialog(viewModel: $viewModel.scanTroubleshootingDialog)

            VStack(spacing: 8) {
                ForEach(0 ..< Constants.skeletonCount, id: \.self) { _ in
                    RedesignedAccountSkeletonCardView()
                        .setShimmerActive(false)
                }
            }
            .padding(.top, 12)

            organizeButton
                .padding(.top, 20)
        }
        .padding(.horizontal, 12)
        .bindAlert($viewModel.alert)
        .frame(maxHeight: .infinity, alignment: .top)
    }
}

// MARK: - Subviews

private extension LockedWalletMainContentRedesignedView {
    var organizeButton: some View {
        TangemButtonV2(
            label: viewModel.organizeTokensButtonTitle,
            accessibilityLabel: viewModel.organizeTokensButtonTitle,
            action: {}
        )
        .iconStart(Assets.OrganizeTokens.filterIcon)
        .styleType(.secondary)
        .size(.x9)
        .disabled(true)
    }
}

// MARK: - Constants

private extension LockedWalletMainContentRedesignedView {
    enum Constants {
        static let skeletonCount = 2
    }
}

// MARK: - Previews

#Preview("Multi-wallet") {
    LockedWalletMainContentRedesignedView(
        viewModel: LockedWalletMainContentViewModel(
            userWalletModel: FakeUserWalletModel.wallet3Cards,
            isMultiWallet: true,
            lockedUserWalletDelegate: nil,
            coordinator: MainCoordinator()
        )
    )
    .infinityFrame()
    .background(DesignSystem.Color.bgPrimary.edgesIgnoringSafeArea(.all))
}

#Preview("Single-wallet") {
    LockedWalletMainContentRedesignedView(
        viewModel: LockedWalletMainContentViewModel(
            userWalletModel: FakeUserWalletModel.twins,
            isMultiWallet: false,
            lockedUserWalletDelegate: nil,
            coordinator: MainCoordinator()
        )
    )
    .infinityFrame()
    .background(DesignSystem.Color.bgPrimary.edgesIgnoringSafeArea(.all))
}
