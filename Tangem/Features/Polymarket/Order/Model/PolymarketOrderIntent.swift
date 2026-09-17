//
//  PolymarketOrderIntent.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemPolymarket

enum PolymarketOrderIntent {
    case buy(balance: AnyPublisher<Decimal?, Never>)
    case sell(shares: Decimal)
}

extension PolymarketOrderIntent {
    var side: PolymarketOrderSide {
        switch self {
        case .buy: .buy
        case .sell: .sell
        }
    }

    var fractionDigits: Int {
        PolymarketCollateral.decimalCount
    }

    var deductsFeeFromMax: Bool {
        switch self {
        case .buy: true
        case .sell: false
        }
    }

    var availablePublisher: AnyPublisher<Decimal?, Never> {
        switch self {
        case .buy(let balance): balance
        case .sell(let shares): Just(shares).eraseToAnyPublisher()
        }
    }

    func minAmount(from quote: PolymarketOrderQuote) -> Decimal? {
        switch self {
        case .buy:
            let shareFloor = quote.minOrderSize * quote.worstCasePrice

            guard let amountFloor = quote.minOrderAmount else {
                return shareFloor > 0 ? shareFloor : nil
            }

            return max(shareFloor, amountFloor)
        case .sell:
            return quote.minOrderSize > 0 ? quote.minOrderSize : nil
        }
    }
}
