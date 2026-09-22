//
//  CollectiblesAccountProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation

/// Publishes the wallet's single collectibles account. The model is built for every wallet the feature is
/// enabled for, whether or not a vault exists on chain — presence in the account list says nothing, and
/// `CollectiblesAccountModel.hasAccount` is what answers "does this wallet have one".
struct CollectiblesAccountProvider {
    private let accountModel: ThreadSafeLazy<any CollectiblesAccountModel>

    init(builder: CollectiblesAccountBuilder) {
        accountModel = ThreadSafeLazy(builder.buildAccountModel)
    }
}

// MARK: - AccountModelsProvider protocol conformance

extension CollectiblesAccountProvider: AccountModelsProvider {
    var accountModelsPublisher: AnyPublisher<[AccountModel], Never> {
        Deferred { [accountModel] () -> Just<[AccountModel]> in
            guard FeatureProvider.isAvailable(.collectibles) else {
                return Just([])
            }

            return Just([.collectibles(accountModel.value)])
        }
        .eraseToAnyPublisher()
    }
}
