//
//  CommonCoinsService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import Moya

protocol CoinsService {
    func checkContractAddress(contractAddress: String, networkIds: [String]) -> AnyPublisher<[CoinModel], Never>
}

private struct CoinsServiceKey: InjectionKey {
    static var currentValue: CoinsService = CommonCoinsService()
}

extension InjectedValues {
    var coinsService: CoinsService {
        get { Self[CoinsServiceKey.self] }
        set { Self[CoinsServiceKey.self] = newValue }
    }
}
