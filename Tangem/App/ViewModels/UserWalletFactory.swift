//
//  UserWalletFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

class UserWalletFactory {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    func userWallet(from cardInfo: CardInfo, config: UserWalletConfig, userWalletId: UserWalletId) -> UserWallet {
        let name: String
        if !cardInfo.name.isEmpty {
            name = cardInfo.name
        } else {
            name = config.cardName
        }

        let saved = userWalletRepository.userWallets.first(where: { $0.userWalletId == userWalletId.value }) ?? nil

        return UserWallet(
            userWalletId: userWalletId.value,
            name: name,
            card: cardInfo.card,
            associatedCardIds: saved?.associatedCardIds ?? [cardInfo.card.cardId],
            walletData: cardInfo.walletData,
            artwork: cardInfo.artwork.artworkInfo,
            isHDWalletAllowed: cardInfo.card.settings.isHDWalletAllowed,
            hasBackupErrors: saved?.hasBackupErrors
        )
    }
}
