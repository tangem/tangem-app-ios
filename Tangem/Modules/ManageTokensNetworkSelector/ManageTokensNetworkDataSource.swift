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

    // MARK: - Private Implementation

    private let coinId: String?

    // MARK: - Init

    init(coinId: String?) {
        self.coinId = coinId

        userWalletModels = userWalletModels(for: coinId)

        let selectedUserWalletModel = selectedUserWalletModel()
        selectedUserWalletModelPublisher.send(selectedUserWalletModel)
    }

    // MARK: - Private Implementation

    /// Full available list of wallets for selection
    private func userWalletModels(for coinId: String?) -> [UserWalletModel] {
        userWalletRepository.models.filter { userWalletModel in
            let walletCondition = userWalletModel.isMultiWallet && !userWalletModel.isUserWalletLocked

            if let coinId {
                return walletCondition && userWalletModel.config.supportedBlockchains.contains(where: { $0.coinId == coinId })
            } else {
                return walletCondition
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
