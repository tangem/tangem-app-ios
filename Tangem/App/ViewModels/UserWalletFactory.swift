//
//  UserWalletFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

class UserWalletFactory {
    func userWallet(from cardInfo: CardInfo, config: UserWalletConfig, userWalletId: UserWalletId) -> UserWallet {
        let name: String
        if !cardInfo.appearance.name.isEmpty {
            name = cardInfo.appearance.name
        } else {
            name = config.cardName
        }

        return UserWallet(
            userWalletId: userWalletId.value,
            name: name,
            card: cardInfo.card,
            associatedCardIds: [cardInfo.card.cardId],
            walletData: cardInfo.walletData,
            artwork: cardInfo.appearance.artwork.artworkInfo,
            isHDWalletAllowed: cardInfo.card.settings.isHDWalletAllowed
        )
    }
}
