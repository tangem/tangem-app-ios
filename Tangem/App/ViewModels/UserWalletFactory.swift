//
//  UserWalletFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

class UserWalletFactory {
    init() { }

    func userWallet(from cardViewModel: CardViewModel) -> UserWallet {
        let walletData: DefaultWalletData = cardViewModel.walletData

        let name: String
        if !cardViewModel.name.isEmpty {
            name = cardViewModel.name
        } else {
            name = cardViewModel.defaultName
        }

        return UserWallet(
            userWalletId: cardViewModel.card.userWalletId,
            name: name,
            card: cardViewModel.card,
            walletData: walletData,
            artwork: cardViewModel.artworkInfo,
            isHDWalletAllowed: cardViewModel.card.settings.isHDWalletAllowed
        )
    }
}
