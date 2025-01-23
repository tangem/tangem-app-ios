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
    func balance(walletModel: WalletModel, type: CachedBalanceType) -> CachedBalance? {
        storage.balance(for: walletModel.id, userWalletId: userWalletId, type: type)
    }

    func store(balance: CachedBalance, for walletModel: WalletModel, type: CachedBalanceType) {
        storage.store(balance: balance, type: type, id: walletModel.id, userWalletId: userWalletId)
    }
}
