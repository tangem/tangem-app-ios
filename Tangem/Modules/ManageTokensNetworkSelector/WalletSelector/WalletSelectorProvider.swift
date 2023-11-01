//
//  WalletSelectorProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

/// This structure implement filter wallet to display ManageTokens list wallet selector and first selection wallet
struct WalletSelectorProvider {
    // MARK: - Properties

    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    // MARK: - Implementation

    /// Full Available list of wallets for selection
    func listWalletForSelector() -> [UserWalletModel] {
        userWalletRepository.models.filter { userWalletModel in
            userWalletModel.isMultiWallet && !userWalletModel.isUserWalletLocked
        }
    }

    /// Return of first selected wallet for diplay
    func currentWalletSelected() -> UserWalletModel? {
        if let selectedUserModelModel = userWalletRepository.selectedUserModelModel,
           !selectedUserModelModel.isUserWalletLocked {
            return selectedUserModelModel
        }

        return userWalletRepository.models.first(where: { !$0.isUserWalletLocked })
    }
}
