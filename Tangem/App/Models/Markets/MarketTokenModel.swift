//
//  MarketTokenModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct MarketTokenModel: Identifiable, Decodable {
    let id: String
    let name: String
    let symbol: String
    let active: Bool
    let imageURL: String
    let currentPrice: Decimal
    let priceChangePercentage: [MarketPriceIntervalType: Decimal]
    let marketRaiting: String
    let marketCup: String
}
