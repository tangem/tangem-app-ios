//
//  TokenBalancesStorage 2.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol TokenBalancesStorage {
    func store(balance: CachedBalance, type: CachedBalanceType, id: WalletModelId, userWalletId: UserWalletId)
    func balance(for id: WalletModelId, userWalletId: UserWalletId, type: CachedBalanceType) -> CachedBalance?
}

private struct TokenBalancesStorageKey: InjectionKey {
    static var currentValue: TokenBalancesStorage = CommonTokenBalancesStorage()
}

extension InjectedValues {
    var tokenBalancesStorage: TokenBalancesStorage {
        get { Self[TokenBalancesStorageKey.self] }
        set { Self[TokenBalancesStorageKey.self] = newValue }
    }
}
