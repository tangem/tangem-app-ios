//
//  ExchangeItems.swift
//  TangemExchange
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

public struct ExchangeItems {
    public let source: Currency
    public let destination: Currency

    public var sourceBalance: CurrencyBalance

    public init(
        source: Currency,
        destination: Currency,
        sourceBalance: CurrencyBalance = .zero
    ) {
        self.source = source
        self.destination = destination
        self.sourceBalance = sourceBalance
    }
}

public struct CurrencyBalance {
    public let balance: Decimal
    public let fiatBalance: Decimal

    public init(balance: Decimal, fiatBalance: Decimal) {
        self.balance = balance
        self.fiatBalance = fiatBalance
    }
}

public extension CurrencyBalance {
    static let zero = CurrencyBalance(balance: 0, fiatBalance: 0)
}
