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
}
