//
//  YieldModuleDTO+MarketInfo.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BigInt
import TangemFoundation

extension YieldModuleDTO.Response {
    struct MarketsInfo: Decodable {
        let tokens: [MarketInfo]
        let lastUpdatedAt: Date
    }

    struct MarketInfo: Decodable, Equatable {
        let tokenAddress: String
        let tokenSymbol: String
        let tokenName: String
        let apy: Decimal
        let supplyCap: String
        let isActive: Bool
        let decimals: Int
        let chainId: Int?
        let chain: String
        @FlexibleDecimal var maxFeeNative: Decimal?
        @FlexibleDecimal var maxFeeUSD: Decimal?
    }
}
