//
//  PolymarketAccountAggregator.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

enum PolymarketAccountAggregator {
    static func polymarketAccountModel(from accountModels: [AccountModel]) -> (any PolymarketAccountModel)? {
        let polymarketAccountModels = accountModels.compactMap { accountModel -> (any PolymarketAccountModel)? in
            switch accountModel {
            case .polymarket(let polymarketAccountModel): polymarketAccountModel
            case .standard, .joint, .tangemPay, .collectibles: nil
            }
        }

        assert(polymarketAccountModels.count < 2)

        return polymarketAccountModels.first
    }

    static func polymarketAccountModel(from accountModelsManager: AccountModelsManager) -> (any PolymarketAccountModel)? {
        polymarketAccountModel(from: accountModelsManager.accountModels)
    }

    static func polymarketAccountModelPublisher(
        from accountModelsManager: AccountModelsManager
    ) -> AnyPublisher<(any PolymarketAccountModel)?, Never> {
        accountModelsManager
            .accountModelsPublisher
            .map(polymarketAccountModel(from:))
            .removeDuplicates { $0?.id == $1?.id }
            .eraseToAnyPublisher()
    }
}
