//
//  ExchangeItems.swift
//  TangemExchange
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

public struct ExchangeItems {
    public var source: Currency
    public var destination: Currency

    public var sourceBalance: CurrencyBalance
    public var destinationBalance: CurrencyBalance?

    init(
        source: Currency,
        destination: Currency,
        sourceBalance: CurrencyBalance = CurrencyBalance(balance: 0, fiatBalance: 0),
        destinationBalance: CurrencyBalance? = nil
    ) {
        self.source = source
        self.destination = destination
        self.sourceBalance = sourceBalance
        self.destinationBalance = destinationBalance
    }
}

public struct CurrencyBalance {
    public let balance: Decimal
    public let fiatBalance: Decimal
}
