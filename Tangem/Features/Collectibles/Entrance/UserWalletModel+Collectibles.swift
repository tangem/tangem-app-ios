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
        guard !isUserWalletLocked, config.hasFeature(.multiCurrency) else {
            return false
        }

        return (try? keysRepository.masterKey(curve: CollectiblesAccountKeyPath.curve(for: config))) != nil
    }

    func collectiblesAccountModel() -> (any CollectiblesAccountModel)? {
        AccountModelsAggregator(.collectibles).model(from: accountModelsManager)
    }
}
