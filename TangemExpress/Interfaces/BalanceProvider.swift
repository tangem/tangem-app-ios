//
//  BalanceProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

public protocol BalanceProvider {
    func getBalance() throws -> Decimal
    func getFeeCurrencyBalance() -> Decimal
}
