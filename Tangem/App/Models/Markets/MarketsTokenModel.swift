//
//  MarketsTokenModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct MarketsTokenModel: Identifiable, Decodable {
    let id: String
    let name: String
    let symbol: String
    let active: Bool
    let imageUrl: String
    let currentPrice: Decimal
    let priceChangePercentage: [MarketsPriceIntervalType: Decimal]
    let marketRating: String
    let marketCap: String
}
