//
//  TokenBalancesRepositoryMock.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

struct TokenBalancesRepositoryMock: TokenBalancesRepository {
    func balance(walletModelId: WalletModelId, type: CachedBalanceType) -> CachedBalance? { nil }

    func store(balance: CachedBalance, for walletModelId: WalletModelId, type: CachedBalanceType) {}
}
