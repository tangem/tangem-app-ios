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
        switch self {
        case .buy: min(PolymarketCollateral.decimalCount, Constants.centFractionDigits)
        case .sell: PolymarketCollateral.decimalCount
        }
    }

    /// A sale is picked in whole tokens, but a holding is rarely a whole number, so Max still has to
    /// name the exact size and the field has to be able to show it.
    var stepFractionDigits: Int {
        switch self {
        case .buy: fractionDigits
        case .sell: 0
        }
    }

    func floor(balance: Decimal) -> Decimal {
        switch self {
        case .buy: 0
        case .sell: min(Constants.wholeShare, balance)
        }
    }

    var maxOffersWholePosition: Bool {
        switch self {
        case .buy: false
        case .sell: true
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
        case .sell(let shares):
            return min(Constants.wholeShare, shares)
        }
    }
}

// MARK: - Constants

private extension PolymarketOrderIntent {
    enum Constants {
        static let wholeShare: Decimal = 1
        static let centFractionDigits = 2
    }
}
