//
//  WalletSelectorProvider.swift
//  Tangem
//
//  Created by skibinalexander on 01.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

/// This structure implement filter wallet to display ManageTokens list wallet selector and first selection wallet
struct WalletSelectorProvider {
    // MARK: - Properties

    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    // MARK: - Implementation

    /// Full Available list of wallets for selection
    func fetchListWalletForSelector() -> [UserWallet] {
        userWalletRepository.models.filter { userWalletModel in
            userWalletModel.isMultiWallet && !userWalletModel.isUserWalletLocked
        }.map {
            $0.userWallet
        }
    }

    /// Return of first selected wallet for diplay
    func fetchCurrentWalletSelected() -> UserWalletModel? {
        let currentUserWalletModel = userWalletRepository.models.first(where: { userWalletModel in
            return userWalletModel.userWalletId.value == userWalletRepository.selectedUserWalletId
        })

        // If current wallet already selected for right path condition
        if let currentUserWalletModel, !currentUserWalletModel.isUserWalletLocked {
            return currentUserWalletModel
        }

        return userWalletRepository.models.first(where: { !$0.isUserWalletLocked })
    }
}
