//
//  YieldIncentivesManagerProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

/// Hands out one incentives manager per `(chainId, userAddress)`: the resource is per user and chain,
/// so token-level yield managers on the same chain share the cache and the in-flight request.
final class YieldIncentivesManagerProvider {
    private struct Key: Hashable {
        let chainId: Int
        let userAddress: String
    }

    private let managers = OSAllocatedUnfairLock(initialState: [Key: CommonYieldIncentivesManager]())

    func manager(chainId: Int, userAddress: String) -> YieldIncentivesManager {
        let key = Key(chainId: chainId, userAddress: userAddress.lowercased())

        return managers.withLock { storage in
            if let manager = storage[key] {
                return manager
            }

            let manager = CommonYieldIncentivesManager(chainId: chainId, userAddress: userAddress)
            storage[key] = manager
            return manager
        }
    }
}

private struct YieldIncentivesManagerProviderKey: InjectionKey {
    static var currentValue = YieldIncentivesManagerProvider()
}

extension InjectedValues {
    var yieldIncentivesManagerProvider: YieldIncentivesManagerProvider {
        get { Self[YieldIncentivesManagerProviderKey.self] }
        set { Self[YieldIncentivesManagerProviderKey.self] = newValue }
    }
}
