//
//  UserWalletId.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

extension UserWalletId {
    init?(cardInfo: CardInfo) {
        let config = UserWalletConfigFactory().makeConfig(cardInfo: cardInfo)
        self.init(config: config)
    }

    init?(config: UserWalletConfig) {
        guard let seed = config.userWalletIdSeed else {
            return nil
        }

        self.init(with: seed)
    }
}
