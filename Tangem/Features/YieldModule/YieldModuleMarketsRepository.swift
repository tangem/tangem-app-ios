//
//  YieldModuleMarketsRepository.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

protocol YieldModuleMarketsRepository {
    func store(markets: CachedYieldModuleMarkets)
    func markets() -> CachedYieldModuleMarkets?
    func marketInfo(for contractAddress: String) -> CachedYieldModuleMarket?
}

final class CommonYieldModuleMarketsRepository {
    private let storage = CachesDirectoryStorage(file: .cachedYieldMarkets)

    init() {}
}

extension CommonYieldModuleMarketsRepository: YieldModuleMarketsRepository {
    func store(markets: CachedYieldModuleMarkets) {
        storage.store(value: markets)
    }

    func markets() -> CachedYieldModuleMarkets? {
        try? storage.value()
    }

    func marketInfo(for contractAddress: String) -> CachedYieldModuleMarket? {
        markets()?.markets.first { $0.tokenContractAddress == contractAddress }
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
    let chainId: Int?
    let maxFeeNative: Decimal?
    let maxFeeUSD: Decimal?
}
