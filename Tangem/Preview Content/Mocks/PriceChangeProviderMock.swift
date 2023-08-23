//
//  PriceChangeProviderMock.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk

// [REDACTED_TODO_COMMENT]
class PriceChangeProviderMock: PriceChangeProvider {
    var priceChangePublisher: AnyPublisher<Void, Never> { .just }

    func change(for currencyCode: String, in blockchain: Blockchain) -> Double {
        0
    }
}
