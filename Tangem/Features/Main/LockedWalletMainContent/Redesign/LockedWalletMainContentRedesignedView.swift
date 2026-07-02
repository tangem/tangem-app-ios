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

struct LockedWalletMainContentRedesignedView: View {
    @ObservedObject var viewModel: LockedWalletMainContentViewModel

    var body: some View {
        VStack(spacing: .unit(.x2)) {
            NotificationBannerContainer(
                items: viewModel.notificationBannerItems,
                stackingType: .carousel
            )
            .confirmationDialog(viewModel: $viewModel.scanTroubleshootingDialog)

            ForEach(0 ..< Constants.skeletonCount, id: \.self) { _ in
                RedesignedAccountSkeletonCardView()
            }
        }
        .padding(.horizontal, .unit(.x3))
        .bindAlert($viewModel.alert)
        .frame(maxHeight: .infinity, alignment: .top)
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
    .background(Color.Tangem.Surface.level2.edgesIgnoringSafeArea(.all))
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
    .background(Color.Tangem.Surface.level2.edgesIgnoringSafeArea(.all))
}
