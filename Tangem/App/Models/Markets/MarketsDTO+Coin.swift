//
//  MarketsDTO+Coin.swift
//  Tangem
//
//  Created by Andrew Son on 27/06/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

extension MarketsDTO {
    enum Coins {}
}

extension MarketsDTO.Coins {
    struct Request: Encodable {
        let tokenId: TokenItemId
        let currency: String
        let language: String
    }

    struct Response: Codable {
        let id: String
        let name: String
        let symbol: String
        let active: Bool
        let currentPrice: Decimal
        let priceChangePercentage: [String: Decimal]
        let networks: [NetworkModel]?
        let shortDescription: String?
        let fullDescription: String?
        let insights: Insights?
        let links: MarketsTokenDetailsLinks
        let metrics: MarketsTokenDetailsMetrics?
        let pricePerformance: [String: MarketsPricePerformanceData]
    }

    struct Insights: Codable {
        let holdersChange: [String: Decimal?]
        let liquidityChange: [String: Decimal?]
        let buyPressureChange: [String: Decimal?]
        let experiencedBuyerChange: [String: Decimal?]
    }
}
