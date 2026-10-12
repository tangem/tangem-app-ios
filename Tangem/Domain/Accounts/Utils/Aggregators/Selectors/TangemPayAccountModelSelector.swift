//
//  TangemPayAccountModelSelector.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

/// The wallet's TangemPay account.
struct TangemPayAccountModelSelector: AccountModelsSelector {
    func select(from accountModels: [AccountModel]) -> (any TangemPayAccountModel)? {
        let tangemPayAccountModels = accountModels.compactMap { accountModel -> (any TangemPayAccountModel)? in
            switch accountModel {
            case .standard, .joint: nil
            case .tangemPay(let tangemPayAccountModel): tangemPayAccountModel
            case .polymarket, .collectibles: nil
            }
        }

        assert(tangemPayAccountModels.count < 2)
        return tangemPayAccountModels.first
    }

    func selectedPublisher(
        from accountModelsPublisher: AnyPublisher<[AccountModel], Never>
    ) -> AnyPublisher<(any TangemPayAccountModel)?, Never> {
        accountModelsPublisher.map(select(from:)).eraseToAnyPublisher()
    }
}

extension AccountModelsSelector where Self == TangemPayAccountModelSelector {
    static var tangemPay: Self {
        TangemPayAccountModelSelector()
    }
}
