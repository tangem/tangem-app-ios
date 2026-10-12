//
//  CollectiblesAccountModelSelector.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

/// The wallet's collectibles account.
struct CollectiblesAccountModelSelector: AccountModelsSelector {
    func select(from accountModels: [AccountModel]) -> (any CollectiblesAccountModel)? {
        let collectiblesAccountModels = accountModels.compactMap { accountModel -> (any CollectiblesAccountModel)? in
            switch accountModel {
            case .standard, .joint, .tangemPay, .polymarket: nil
            case .collectibles(let collectiblesAccountModel): collectiblesAccountModel
            }
        }

        assert(collectiblesAccountModels.count < 2)
        return collectiblesAccountModels.first
    }

    /// The account outlives the lists it arrives in, so subscribers are only woken when it is a different one.
    func selectedPublisher(
        from accountModelsPublisher: AnyPublisher<[AccountModel], Never>
    ) -> AnyPublisher<(any CollectiblesAccountModel)?, Never> {
        accountModelsPublisher
            .map(select(from:))
            .removeDuplicates { $0?.id == $1?.id }
            .eraseToAnyPublisher()
    }
}

extension AccountModelsSelector where Self == CollectiblesAccountModelSelector {
    static var collectibles: Self {
        CollectiblesAccountModelSelector()
    }
}
