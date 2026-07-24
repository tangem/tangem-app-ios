//
//  ForYouCoordinator+Staking.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

@MainActor
extension ForYouCoordinator {
    func openEarnStaking(walletModel: any WalletModel, userWalletModel: any UserWalletModel) {
        guard let stakingManager = walletModel.stakingManager else {
            return
        }

        let input = SendInput(userWalletInfo: userWalletModel.userWalletInfo, walletModel: walletModel)
        let coordinator = StakingDetailsCoordinator(
            dismissAction: { [weak self] _ in self?.stakingCoordinator = nil },
            popToRootAction: popToRootAction
        )
        coordinator.start(with: .init(sendInput: input, manager: stakingManager))
        stakingCoordinator = coordinator
    }
}
