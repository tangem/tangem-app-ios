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

    public let sourceBalance: CurrencyBalance
    public let destinationBalance: CurrencyBalance?

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
