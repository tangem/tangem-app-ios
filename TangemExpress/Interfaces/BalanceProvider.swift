//
//  BalanceProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public typealias ExpressBalanceProvider = TangemExpress.BalanceProvider

public protocol BalanceProvider {
    func getBalance() throws -> Decimal
    func getFeeCurrencyBalance() -> Decimal
}

public extension BalanceProvider {
    var feeCurrencyHasPositiveBalance: Bool {
        getFeeCurrencyBalance() > 0
    }
}
