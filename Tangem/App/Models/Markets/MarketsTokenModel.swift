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
    let currentPrice: Decimal?
    let priceChangePercentage: [String: Decimal]
    let marketRating: Int?
    let marketCap: Decimal?
}
