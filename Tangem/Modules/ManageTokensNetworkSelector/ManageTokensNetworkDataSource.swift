//
//  ManageTokensNetworkDataSource.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class ManageTokensNetworkDataSource: WalletSelectorDataSource {
    // MARK: - Injected

    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    var userWalletModels: [UserWalletModel] = []
    var selectedUserWalletModelPublisher: CurrentValueSubject<UserWalletModel?, Never> = .init(nil)

    // MARK: - Init

    init(tokenItems: [TokenItem]) {
        userWalletModels = userWalletModels(for: tokenItems)

        let selectedUserWalletModel = selectedUserWalletModel()
        selectedUserWalletModelPublisher.send(selectedUserWalletModel)
    }

    // MARK: - Private Implementation

    /// Full available list of wallets for selection
    private func userWalletModels(for tokenItems: [TokenItem]) -> [UserWalletModel] {
        userWalletRepository.models.filter { userWalletModel in
            let walletCondition = userWalletModel.isMultiWallet && !userWalletModel.isUserWalletLocked

            if tokenItems.isEmpty {
                return walletCondition
            } else {
                return walletCondition && !userWalletModel.config.supportedBlockchains.filter { blockchain in
                    tokenItems.map { $0.blockchain }.contains(blockchain)
                }.isEmpty
            }
        }
    }

    /// Return of first selected wallet for display
    private func selectedUserWalletModel() -> UserWalletModel? {
        userWalletModels.first { userWalletModel in
            userWalletModel.userWalletId == userWalletRepository.selectedUserModelModel?.userWalletId
        } ?? userWalletModels.first
    }
}
