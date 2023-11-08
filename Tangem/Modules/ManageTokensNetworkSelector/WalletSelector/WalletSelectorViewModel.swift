//
//  WalletSelectorViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class WalletSelectorViewModel: ObservableObject {
    var itemViewModels: [WalletSelectorItemViewModel] = []

    weak var dataSource: WalletSelectorDataSource?
    weak var delegate: WalletSelectorDelegate?

    init(dataSource: WalletSelectorDataSource?) {
        self.dataSource = dataSource
    }

    func bind() {
        itemViewModels = dataSource?.userWalletModels.map { userWalletModel in
            WalletSelectorItemViewModel(
                userWallet: userWalletModel,
                isSelected: userWalletModel.userWalletId == dataSource?.selectedUserWalletId,
                cardImageProvider: CardImageProvider()
            ) { [weak self] userWalletId in
                self?.dataSource?.selectedUserWalletId = userWalletId
            }
        } ?? []
    }
}
