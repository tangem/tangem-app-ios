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

    func userWallet(from cardInfo: CardInfo, config: UserWalletConfig) -> UserWallet {
        let walletData: DefaultWalletData = cardInfo.walletData

        let name: String
        if !cardInfo.name.isEmpty {
            name = cardInfo.name
        } else {
            name = config.cardName
        }

        return UserWallet(
            userWalletId: cardInfo.card.userWalletId,
            name: name,
            card: cardInfo.card,
            walletData: walletData,
            artwork: nil,
            isHDWalletAllowed: cardInfo.card.settings.isHDWalletAllowed
        )
    }

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
