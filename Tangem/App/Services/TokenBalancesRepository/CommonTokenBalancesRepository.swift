//
//  CommonTokenBalancesRepository.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

struct CommonTokenBalancesRepository {
    @Injected(\.tokenBalancesStorage)
    private var storage: TokenBalancesStorage
    private let userWalletId: UserWalletId

    init(userWalletId: UserWalletId) {
        self.userWalletId = userWalletId
    }
}

// MARK: - TokenBalancesRepository

extension CommonTokenBalancesRepository: TokenBalancesRepository {
    func balance(walletModelId: WalletModelId, type: CachedBalanceType) -> CachedBalance? {
        storage.balance(for: walletModelId, userWalletId: userWalletId, type: type)
    }

    func store(balance: CachedBalance, for walletModelId: WalletModelId, type: CachedBalanceType) {
        storage.store(balance: balance, type: type, id: walletModelId, userWalletId: userWalletId)
    }
}
