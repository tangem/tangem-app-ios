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
                userWalletModel: userWalletModel,
                isSelected: userWalletModel.userWalletId == selectedUserWalletModelPublisher.value?.userWalletId,
                cardImageProvider: CardImageProvider()
            ) { [weak self] userWalletId in
                guard let self = self else { return }

                let selectedUserWalletModel = userWalletModels.first(where: { $0.userWalletId == userWalletId })
                selectedUserWalletModelPublisher.send(selectedUserWalletModel)
            }
        }
    }

    // MARK: - Init

    init(_ dataSource: ManageTokensDataSource) {
        userWalletModels = dataSource.userWalletModels.filter { $0.isMultiWallet }

        let selectedUserWalletModel = userWalletModels.first { userWalletModel in
            userWalletModel.userWalletId == dataSource.defaultUserWalletModel?.userWalletId
        } ?? userWalletModels.first

        selectedUserWalletModelPublisher.send(selectedUserWalletModel)
    }
}
