//
//  TokenBalancesStorage 2.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

protocol TokenBalancesStorage {
    func store(balance: CachedBalance, type: CachedBalanceType, id: WalletModelId, userWalletId: UserWalletId)
    func balance(for id: WalletModelId, userWalletId: UserWalletId, type: CachedBalanceType) -> CachedBalance?
}
