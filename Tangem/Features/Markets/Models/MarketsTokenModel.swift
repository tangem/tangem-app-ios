//
//  MarketsTokenModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking
import TangemFoundation

struct MarketsTokenModel: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let symbol: String
    let currentPrice: Decimal?
    let priceChangePercentage: [String: Decimal?]
    let marketRating: Int?
    let maxYieldApy: Decimal?
    let marketCap: Decimal?
    let isUnderMarketCapLimit: Bool?
    let stakingOpportunities: [StakingOpportunity]?
    let networks: [NetworkModel]?

    struct StakingOpportunity: Codable, Hashable {
        let id: UInt64
        let apy: String
        let networkId: String
        let rewardType: String
    }
}
