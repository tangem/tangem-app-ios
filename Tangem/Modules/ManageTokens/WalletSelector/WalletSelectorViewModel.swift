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
    var itemViewModels: [WalletSelectorCellViewModel] = []

    private unowned let coordinator: WalletSelectorRoutable

    init(userWallets: [UserWallet], currentUserWalletId: Data, coordinator: WalletSelectorRoutable) {
        self.coordinator = coordinator
        itemViewModels = userWallets.map { userWallet in
            WalletSelectorCellViewModel(
                userWallet: userWallet,
                isSelected: userWallet.userWalletId == currentUserWalletId,
                cardImageProvider: CardImageProvider()
            ) { [weak self] in
                self?.didTapWallet(with: userWallet)
            }
        }
    }

    func didTapWallet(with userWallet: UserWallet) {
        for itemViewModel in itemViewModels {
            itemViewModel.isSelected = userWallet.userWalletId == itemViewModel.userWallet.userWalletId
        }

        coordinator.didSelectWallet(with: userWallet.userWalletId)
    }
}
