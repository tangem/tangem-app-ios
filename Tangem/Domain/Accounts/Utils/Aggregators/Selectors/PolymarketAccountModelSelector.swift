//
//  PolymarketAccountModelSelector.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

/// The wallet's Polymarket account.
struct PolymarketAccountModelSelector: AccountModelsSelector {
    func select(from accountModels: [AccountModel]) -> (any PolymarketAccountModel)? {
        let polymarketAccountModels = accountModels.compactMap { accountModel -> (any PolymarketAccountModel)? in
            switch accountModel {
            case .standard, .joint, .tangemPay: nil
            case .polymarket(let polymarketAccountModel): polymarketAccountModel
            case .collectibles: nil
            }
        }

        assert(polymarketAccountModels.count < 2)
        return polymarketAccountModels.first
    }

    /// The account outlives the lists it arrives in, so subscribers are only woken when it is a different one.
    func selectedPublisher(
        from accountModelsPublisher: AnyPublisher<[AccountModel], Never>
    ) -> AnyPublisher<(any PolymarketAccountModel)?, Never> {
        accountModelsPublisher
            .map(select(from:))
            .removeDuplicates { $0?.id == $1?.id }
            .eraseToAnyPublisher()
    }
}

extension AccountModelsSelector where Self == PolymarketAccountModelSelector {
    static var polymarket: Self {
        PolymarketAccountModelSelector()
    }
}
