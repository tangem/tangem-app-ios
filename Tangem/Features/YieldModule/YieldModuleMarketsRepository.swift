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
}

extension CommonYieldModuleMarketsRepository: YieldModuleMarketsRepository {
    func store(markets: CachedYieldModuleMarkets) {
        storage.store(value: markets)
    }

    func markets() -> CachedYieldModuleMarkets? {
        try? storage.value()
    }

    func marketInfo(for contractAddress: String) -> CachedYieldModuleMarket? {
        // The backend lowercases token addresses while the wallet stores them in EIP-55 checksum form —
        // compare case-insensitively so the cached warm start matches the live state.
        markets()?.markets.first { $0.tokenContractAddress.caseInsensitiveEquals(to: contractAddress) }
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
