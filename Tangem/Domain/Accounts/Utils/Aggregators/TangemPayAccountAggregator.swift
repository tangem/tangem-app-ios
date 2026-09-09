//
//  TangemPayAccountAggregator.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

/// Picks the TangemPay account out of the account list. A wallet has at most one, so the answer is the account itself
/// rather than a list of them.
enum TangemPayAccountAggregator {
    static func tangemPayAccountModel(from accountModels: [AccountModel]) -> (any TangemPayAccountModel)? {
        let tangemPayAccountModels = accountModels.compactMap { accountModel -> (any TangemPayAccountModel)? in
            switch accountModel {
            case .tangemPay(let tangemPayAccountModel): tangemPayAccountModel
            case .standard, .joint, .polymarket, .collectibles: nil
            }
        }

        assert(tangemPayAccountModels.count < 2)

        return tangemPayAccountModels.first
    }

    static func tangemPayAccountModel(from accountModelsManager: AccountModelsManager) -> (any TangemPayAccountModel)? {
        tangemPayAccountModel(from: accountModelsManager.accountModels)
    }

    static func tangemPayAccountModelPublisher(
        from accountModelsManager: AccountModelsManager
    ) -> AnyPublisher<(any TangemPayAccountModel)?, Never> {
        accountModelsManager
            .accountModelsPublisher
            .map(tangemPayAccountModel(from:))
            .eraseToAnyPublisher()
    }
}
