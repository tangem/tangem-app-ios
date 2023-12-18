//
//  TokenQuote.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct TokenQuote: Hashable {
    let currencyId: String
    let change: Decimal?
    let price: Decimal
    let prices24h: [Double]?
    let currencyCode: String
}
