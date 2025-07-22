//
//  CommonUserWalletModel+Mock.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

extension CommonUserWalletModel {
    static let mock = CommonUserWalletModelFactory().makeModel(
        walletInfo: .cardWallet(CardMock.wallet.cardInfo),
        keys: .cardWallet(keys: CardMock.wallet.cardInfo.card.wallets)
    )

    static let visaMock = CommonUserWalletModelFactory().makeModel(
        walletInfo: .cardWallet(CardMock.visa.cardInfo),
        keys: .cardWallet(keys: CardMock.wallet.cardInfo.card.wallets)
    )
}
