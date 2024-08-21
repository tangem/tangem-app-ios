//
//  Quotes.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct Quote: Decodable {
    /// Coin id from request
    let id: String
    /// Current coin price
    let price: Decimal
    /// Price change in percent
    let priceChange: Decimal?
    /// Price change in last 7 days
    let priceChange7d: Decimal?
    /// Price change in last 30 days
    let priceChange30d: Decimal?
    /// Price change in value on 24h
    let prices24h: [Double]?
}
