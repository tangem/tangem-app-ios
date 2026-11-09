//
//  UserWalletRepository+MobileWalletLimit.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension UserWalletRepository {
    var isMobileWalletsLimitReached: Bool {
        MobileWalletLimit.isReached(in: models)
    }

    func isMobileWalletsLimitReached(for userWalletModel: UserWalletModel) -> Bool {
        MobileWalletLimit.isReached(for: userWalletModel, in: models)
    }
}
