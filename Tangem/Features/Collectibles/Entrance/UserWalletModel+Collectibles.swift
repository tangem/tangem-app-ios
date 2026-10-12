//
//  UserWalletModel+Collectibles.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension UserWalletModel {
    var isCollectiblesEligible: Bool {
        !isUserWalletLocked && config.hasFeature(.multiCurrency)
    }

    func collectiblesAccountModel() -> (any CollectiblesAccountModel)? {
        AccountModelsAggregator(.collectibles).model(from: accountModelsManager)
    }
}
