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

    init(dataSource: WalletSelectorDataSource?) {
        self.dataSource = dataSource

        bind()
    }

    func bind() {
        dataSource?.selectedUserWalletModelPublisher.sink(receiveValue: { userWalletModel in
            let itemViewModel = itemViewModels.first(where: { $0.id == userWalletModel. })
        })
        
        itemViewModels = dataSource?.userWalletModels.map { userWalletModel in
            WalletSelectorItemViewModel(
                userWallet: userWalletModel,
                isSelected: userWalletModel.userWalletId == dataSource?.selectedUserWalletModelPublisher.value?.userWalletId,
                cardImageProvider: CardImageProvider()
            ) { [weak self] userWalletId in
                let selectedUserWalletModel = self?.dataSource?.userWalletModels.first(where: { $0.userWalletId == userWalletId })
                self?.dataSource?.selectedUserWalletModelPublisher.send(selectedUserWalletModel)
            }
        } ?? []
    }
}
