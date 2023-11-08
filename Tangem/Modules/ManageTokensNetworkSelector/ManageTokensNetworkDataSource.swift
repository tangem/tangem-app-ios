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

    init(coinId: String?) {
        userWalletModels = userWalletModels(for: coinId)
        selectedUserWalletModelPublisher = .init(selectedUserWalletModel(from: userWalletModels))
    }

    // MARK: - Implementation

    /// Full Available list of wallets for selection
    func userWalletModels(for coinId: String?) -> [UserWalletModel] {
        userWalletRepository.models.filter { userWalletModel in
            let walletCondition = userWalletModel.isMultiWallet && !userWalletModel.isUserWalletLocked

            if let coinId {
                return walletCondition && userWalletModel.config.supportedBlockchains.contains(where: { $0.coinId == coinId })
            } else {
                return walletCondition
            }
        }
    }

    /// Return of first selected wallet for diplay
    func selectedUserWalletModel(from userWalletModels: [UserWalletModel]) -> UserWalletModel? {
        userWalletModels.first { userWalletModel in
            userWalletModel.userWalletId == userWalletRepository.selectedUserModelModel?.userWalletId
        } ?? userWalletModels.first
    }

    /// Return flag if currency selected UserWalletModel is single currency wallet
    func isCurrentSelectedNonMultiUserWalletModel(by coinId: String, with userWalletModels: [UserWalletModel]) -> Bool {
        guard let selectedUserModelModel = userWalletRepository.selectedUserModelModel else {
            return false
        }

        return userWalletModels.isEmpty &&
            !selectedUserModelModel.isMultiWallet &&
            !selectedUserModelModel.config.supportedBlockchains.contains(where: { $0.coinId == coinId })
    }
}
