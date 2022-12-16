//
//  CurrencyPrice.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import TangemExchange

struct CurrencyPrice {
    let value: Decimal
    let currency: Currency

    var formatted: String {
        let amount = value.groupedFormatted(maximumFractionDigits: currency.decimalCount)
        return "\(amount) \(currency.symbol)"
    }

    init(amount: Decimal, currency: Currency) {
        self.value = amount
        self.currency = currency
    }
}
