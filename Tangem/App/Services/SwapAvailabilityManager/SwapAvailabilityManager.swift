//
//  SwapAvailabilityManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine

typealias SwapAvailabilityManager = SwapAvailabilityProvider & SwapAvailabilityController

protocol SwapAvailabilityController {
    func loadSwapAvailability(for items: [TokenItem]) -> AnyPublisher<Void, Error>
    func addTokensIfCanBeSwapped(_ items: [TokenItem])
}

protocol SwapAvailabilityProvider {
    func canSwap(tokenItem: TokenItem) -> Bool
}

private struct SwapAvailabilityManagerKey: InjectionKey {
    static var currentValue: SwapAvailabilityManager = CommonSwapAvailabilityManager()
}

extension InjectedValues {
    var swapAvailabilityController: SwapAvailabilityController {
        manager
    }

    var swapAvailabilityProvider: SwapAvailabilityProvider {
        manager
    }

    private var manager: SwapAvailabilityManager {
        get { Self[SwapAvailabilityManagerKey.self] }
        set { Self[SwapAvailabilityManagerKey.self] = newValue }
    }
}
