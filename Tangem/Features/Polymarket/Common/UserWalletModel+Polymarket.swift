//
//  UserWalletModel+Polymarket.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension UserWalletModel {
    var supportsPolymarket: Bool {
        !isUserWalletLocked && config.hasFeature(.hdWallets)
    }
}
