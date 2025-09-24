//
//  YieldModuleMarketsStorage.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

protocol YieldModuleMarketsStorage {
    func store(markets: CachedYieldModuleMarkets)
    func markets() -> CachedYieldModuleMarkets?
}

final class CommonYieldModuleMarketsStorage {
    private let storage = CachesDirectoryStorage(file: .cachedBalances)

    init() {}
}

extension CommonYieldModuleMarketsStorage: YieldModuleMarketsStorage {
    func store(markets: CachedYieldModuleMarkets) {
        storage.store(value: markets)
    }

    func markets() -> CachedYieldModuleMarkets? {
        try? storage.value()
    }
}

struct CachedYieldModuleMarkets: Codable {
    let markets: [CachedYieldModuleMarket]
    let lastUpdated: Date
}

struct CachedYieldModuleMarket: Codable {
    let tokenContractAddress: String
    let apy: Decimal
    let isActive: Bool
}
