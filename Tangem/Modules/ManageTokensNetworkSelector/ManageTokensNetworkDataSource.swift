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
    // MARK: - Properties

    var userWalletModels: [UserWalletModel] = []
    var selectedUserWalletModelPublisher: CurrentValueSubject<UserWalletModel?, Never> = .init(nil)

    var walletSelectorItemViewModels: [WalletSelectorItemViewModel] {
        userWalletModels.map { userWalletModel in
            WalletSelectorItemViewModel(
                id: userWalletModel.userWalletId,
                name: userWalletModel.config.cardName,
                cardImagePublisher: userWalletModel.cardImagePublisher,
                isSelected: userWalletModel.userWalletId == selectedUserWalletModelPublisher.value?.userWalletId
            ) { [weak self] userWalletId in
                guard let self = self else { return }

                let selectedUserWalletModel = userWalletModels.first(where: { $0.userWalletId == userWalletId })
                selectedUserWalletModelPublisher.send(selectedUserWalletModel)
            }
        }
    }

    // MARK: - Init

    init(_ dataSource: ManageTokensDataSource) {
        userWalletModels = dataSource.userWalletModelsSubject.value.filter { $0.isMultiWallet }

        let selectedUserWalletModel = userWalletModels.first { userWalletModel in
            userWalletModel.userWalletId == dataSource.defaultUserWalletModel?.userWalletId
        } ?? userWalletModels.first

        selectedUserWalletModelPublisher.send(selectedUserWalletModel)
    }
}
