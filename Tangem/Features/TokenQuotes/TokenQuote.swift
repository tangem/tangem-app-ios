//
//  TokenQuote.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct TokenQuote: Hashable, Codable {
    let currencyId: String
    let price: Decimal
    let priceUsd: Decimal?
    let priceChange24h: Decimal?
    let priceChange7d: Decimal?
    let priceChange30d: Decimal?
    let currencyCode: String

    @IgnoredEquatable
    private(set) var date: Date

    init(
        currencyId: String,
        price: Decimal,
        priceUsd: Decimal?,
        priceChange24h: Decimal?,
        priceChange7d: Decimal?,
        priceChange30d: Decimal?,
        currencyCode: String,
        date: Date = .now
    ) {
        self.currencyId = currencyId
        self.price = price
        self.priceUsd = priceUsd
        self.priceChange24h = priceChange24h
        self.priceChange7d = priceChange7d
        self.priceChange30d = priceChange30d
        self.currencyCode = currencyCode
        self.date = date
    }
}
