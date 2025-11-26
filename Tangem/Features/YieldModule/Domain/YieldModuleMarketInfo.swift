//
//  YieldModuleMarketInfo.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BigInt

struct YieldModuleMarketInfo: Codable, Equatable {
    let tokenContractAddress: String
    let apy: Decimal
    let isActive: Bool
    let chainId: Int?
    let maxFeeNative: Decimal?
    let maxFeeUSD: Decimal?
}

extension YieldModuleMarketInfo {
    init(from cached: CachedYieldModuleMarket) {
        self.init(
            tokenContractAddress: cached.tokenContractAddress,
            apy: cached.apy / 100,
            isActive: cached.isActive,
            chainId: cached.chainId,
            maxFeeNative: cached.maxFeeNative,
            maxFeeUSD: cached.maxFeeUSD
        )
    }
}
