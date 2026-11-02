//
//  AccountModelsManager+Collectibles.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import CombineExt
import TangemFoundation

extension AccountModelsManager {
    var collectiblesPendingDerivationNetworksPublisher: AnyPublisher<[BlockchainNetwork], Never> {
        AccountModelsAggregator(.collectibles)
            .modelPublisher(from: self)
            .flatMapLatest { collectiblesAccountModel -> AnyPublisher<[BlockchainNetwork], Never> in
                collectiblesAccountModel?.pendingDerivationNetworksPublisher ?? .just(output: [])
            }
            .receiveOnMain()
            .eraseToAnyPublisher()
    }
}
