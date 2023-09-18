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

    init(userWallets: [UserWallet], currentUserWalletId: Data) {
        itemViewModels = userWallets.map { userWallet in
            return WalletSelectorCellViewModel(
                userWallet: userWallet,
                isSelected: userWallet.userWalletId == currentUserWalletId,
                cardImageProvider: CardImageProvider()
            ) { [weak self] in
                self?.didTapWallet(with: userWallet)
            }
        }
    }

    func didTapWallet(with userWallet: UserWallet) {
        print("DID TAP:", userWallet.name)
    }
}
