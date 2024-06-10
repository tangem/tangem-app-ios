//
//  MarketsTokenModel.swift
//  Tangem
//
//  Created by skibinalexander on 27.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct MarketsTokenModel: Identifiable, Decodable {
    let id: String
    let name: String
    let symbol: String
    let active: Bool
    let currentPrice: Decimal?
    let priceChangePercentage: [String: Decimal]
    let marketRaiting: String?
    let marketCup: String?
}
