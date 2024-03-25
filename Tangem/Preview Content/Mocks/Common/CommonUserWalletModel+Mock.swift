//
//  CommonUserWalletModel+Mock.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

extension CommonUserWalletModel {
    static let mock = CommonUserWalletModel(
        cardInfo: CardInfo(card: .init(card: .walletWithBackup), walletData: .none, name: "", artwork: .noArtwork, primaryCard: nil)
    )
}
