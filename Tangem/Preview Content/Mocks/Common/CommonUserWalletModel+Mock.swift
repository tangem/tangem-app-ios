//
//  CommonUserWalletModel+Mock.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

extension CommonUserWalletModel {
    static let mock = CommonUserWalletModelFactory().makeCommonUserWalletModel(
        cardInfo: CardMock.wallet.cardInfo
    )

    static let visaMock = CommonUserWalletModelFactory().makeCommonUserWalletModel(
        cardInfo: CardMock.visa.cardInfo
    )
}
