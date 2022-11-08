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
    
    func isAvailableForExchange(for amountValue: Decimal) -> Allowance {
        switch currency.type {
        case .coin:
            return .availableForSwap
        case .token:
            if amountValue <= allowance {
                return .availableForSwap
            }
            return .unavailableForSwap
        }
    }
}

extension ExchangeItem {
    enum Allowance {
        case availableForSwap
        case unavailableForSwap
    }
}
