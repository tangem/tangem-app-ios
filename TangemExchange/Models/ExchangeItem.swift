//
//  ExchangeItem.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

class ExchangeItem: Identifiable {
    let isLocked: Bool
    var currency: Currency
    var allowance: Decimal = 0

    init(isLocked: Bool, currency: Currency) {
        self.isLocked = isLocked
        self.currency = currency
    }

    func isAvailableForExchange(for amountValue: Decimal) -> Bool {
        if !currency.isToken {
            return true
        } else {
            if amountValue <= allowance {
                return true
            }
            return false
        }
    }
}
