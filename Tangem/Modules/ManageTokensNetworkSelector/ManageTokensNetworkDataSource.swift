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

    private var _userWalletModels: CurrentValueSubject<[UserWalletModel], Never> = .init([])
    var userWalletModels: [UserWalletModel] { _userWalletModels.value }

    var _selectedUserWalletModel: CurrentValueSubject<UserWalletModel?, Never> = .init(nil)
    var selectedUserWalletModel: [UserWalletModel] { _userWalletModels.value }

    var walletSelectorItemViewModels: [WalletSelectorItemViewModel] {
        userWalletModels.map { userWalletModel in
            WalletSelectorItemViewModel(
                id: userWalletModel.userWalletId,
                name: userWalletModel.config.cardName,
                cardImagePublisher: userWalletModel.cardImagePublisher,
                isSelected: userWalletModel.userWalletId == _selectedUserWalletModel.value?.userWalletId
            ) { [weak self] userWalletId in
                guard let self = self else { return }

                let selectedUserWalletModel = userWalletModels.first(where: { $0.userWalletId == userWalletId })
                _selectedUserWalletModel.send(selectedUserWalletModel)
            }
        }
    }

    // MARK: - Init

    init(_ dataSource: ManageTokensDataSource) {
        _userWalletModels.send(dataSource.userWalletModels.filter { $0.isMultiWallet })

        let selectedUserWalletModel = userWalletModels.first { userWalletModel in
            userWalletModel.userWalletId == dataSource.defaultUserWalletModel?.userWalletId
        } ?? userWalletModels.first

        _selectedUserWalletModel.send(selectedUserWalletModel)
    }
}
