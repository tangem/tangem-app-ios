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

    init(
        source: Currency,
        destination: Currency,
        sourceBalance: CurrencyBalance = CurrencyBalance(balance: 0, fiatBalance: 0)
    ) {
        self.source = source
        self.destination = destination
        self.sourceBalance = sourceBalance
    }
}

public struct CurrencyBalance {
    public let balance: Decimal
    public let fiatBalance: Decimal
}
