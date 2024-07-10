//
//  TokenMarketsDetailsModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct TokenMarketsDetailsModel: Identifiable {
    let id: String
    let name: String
    let symbol: String
    let isActive: Bool
    let currentPrice: Decimal
    let shortDescription: String?
    let fullDescription: String?
    let priceChangePercentage: [String: Decimal]
    let tokenItems: [TokenItem]
    let insights: TokenMarketsDetailsInsights?
}

struct TokenMarketsDetailsInsights {
    let holders: [MarketsPriceIntervalType: Decimal]
    let liquidity: [MarketsPriceIntervalType: Decimal]
    let buyPressure: [MarketsPriceIntervalType: Decimal]
    let experiencedBuyers: [MarketsPriceIntervalType: Decimal]

    init(dto: MarketsDTO.Coins.Insight?) {
        guard let dto else {
            holders = [:]
            liquidity = [:]
            buyPressure = [:]
            experiencedBuyers = [:]
            return
        }

        func mapToInterval(_ dict: [String: Decimal]) -> [MarketsPriceIntervalType: Decimal] {
            return dict.reduce(into: [:]) { partialResult, pair in
                guard let interval = MarketsPriceIntervalType(rawValue: pair.key) else {
                    return
                }

                partialResult[interval] = pair.value
            }
        }

        holders = mapToInterval(dto.holdersChange)
        liquidity = mapToInterval(dto.liquidityChange)
        buyPressure = mapToInterval(dto.buyPressureChange)
        experiencedBuyers = mapToInterval(dto.experiencedBuyerChange)
    }
}
