//
//  TokenBalancesRepository.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol TokenBalancesRepository {
    func balance(walletModel: WalletModel, type: CachedBalanceType) -> CachedBalance?
    func store(balance: CachedBalance, for walletModel: WalletModel, type: CachedBalanceType)
}

struct CachedBalance: Hashable, Codable {
    let balance: Decimal
    let date: Date
}

enum CachedBalanceType: String, Hashable, Codable {
    case available
    case staked
}
