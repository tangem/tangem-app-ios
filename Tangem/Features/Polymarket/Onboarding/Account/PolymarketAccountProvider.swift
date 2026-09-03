//
//  PolymarketAccountProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation

struct PolymarketAccountProvider {
    private let accountModel: ThreadSafeLazy<any PolymarketAccountModel>

    init(builder: PolymarketAccountBuilder) {
        accountModel = ThreadSafeLazy(builder.buildAccountModel)
    }
}

// MARK: - AccountModelsProvider protocol conformance

extension PolymarketAccountProvider: AccountModelsProvider {
    var accountModelsPublisher: AnyPublisher<[AccountModel], Never> {
        Deferred { [accountModel] () -> Just<[AccountModel]> in
            guard FeatureProvider.isAvailable(.polymarket) else {
                return Just([])
            }

            return Just([.polymarket(accountModel.value)])
        }
        .eraseToAnyPublisher()
    }
}
