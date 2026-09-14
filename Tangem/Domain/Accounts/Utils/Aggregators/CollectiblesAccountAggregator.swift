//
//  CollectiblesAccountAggregator.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

enum CollectiblesAccountAggregator {
    static func collectiblesAccountModel(from accountModels: [AccountModel]) -> (any CollectiblesAccountModel)? {
        let collectiblesAccountModels = accountModels.compactMap { accountModel -> (any CollectiblesAccountModel)? in
            switch accountModel {
            case .collectibles(let collectiblesAccountModel): collectiblesAccountModel
            case .standard, .joint, .tangemPay, .polymarket: nil
            }
        }

        assert(collectiblesAccountModels.count < 2)

        return collectiblesAccountModels.first
    }

    static func collectiblesAccountModel(from accountModelsManager: AccountModelsManager) -> (any CollectiblesAccountModel)? {
        collectiblesAccountModel(from: accountModelsManager.accountModels)
    }
}
