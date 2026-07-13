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
        TangemButton(
            content: .combined(
                text: AttributedString(viewModel.organizeTokensButtonTitle),
                icon: Assets.OrganizeTokens.filterIcon,
                iconPosition: .left
            ),
            action: {}
        )
        .setStyleType(.primaryInverse)
        .setButtonState(isLoading: false, isDisabled: true)
        .setSize(.x9)
        .setFont(Font.Tangem.Body14.regular)
    }
}

// MARK: - Constants

private extension LockedWalletMainContentRedesignedView {
    enum Constants {
        static let skeletonCount = 2
    }
}

// MARK: - Previews

#if DEBUG
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
#endif // DEBUG
