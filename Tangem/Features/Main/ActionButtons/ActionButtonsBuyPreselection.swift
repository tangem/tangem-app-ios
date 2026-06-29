//
//  ActionButtonsBuyPreselection.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemFoundation

enum ActionButtonsBuyPreselection {
    static func userWalletId(for userWalletModel: UserWalletModel) -> UserWalletId? {
        guard userWalletModel.config.makeActionButtonsRole().preselectsUserWalletInBuy else {
            return nil
        }

        return userWalletModel.userWalletId
    }
}
