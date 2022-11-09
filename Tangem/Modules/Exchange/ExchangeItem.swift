//
//  ExchangeItem.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import Combine

class ExchangeItem: Identifiable {
    let isLockedForChange: Bool
    var currency: ExchangeCurrency

    var name: String? {
        currency.name
    }

    var symbol: String? {
        currency.symbol
    }

    var decimalCount: Decimal? {
        currency.decimalCount
    }

    var tokenAddress: String {
        currency.contractAddress
    }

    private var allowance: Decimal = 0

    init(isLockedForChange: Bool, currency: ExchangeCurrency) {
        self.isLockedForChange = isLockedForChange
        self.currency = currency
    }

    func updateAllowance(_ allowance: Decimal) {
        self.allowance = allowance
    }

    func isAvailableForExchange(for amountValue: Decimal) -> Bool {
        switch currency.type {
        case .coin:
            return true
        case .token:
            if amountValue <= allowance {
                return true
            }
            return false
        }
    }
}
