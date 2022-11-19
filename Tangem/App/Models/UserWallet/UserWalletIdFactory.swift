//
//  UserWalletIdFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

class UserWalletIdFactory {
    func userWalletId(from cardInfo: CardInfo) -> UserWalletId? {
        let config = UserWalletConfigFactory(cardInfo).makeConfig()
        return userWalletId(config: config)
    }

    func userWalletId(config: UserWalletConfig) -> UserWalletId? {
        guard let seed = config.userWalletIdSeed else { return nil }

        return UserWalletId(with: seed)
    }
}
