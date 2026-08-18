//
//  PolymarketBalanceAllowance.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct PolymarketBalanceAllowance: Hashable, Sendable {
    public let balance: Decimal

    public let allowance: Decimal?

    public init(balance: Decimal, allowance: Decimal?) {
        self.balance = balance
        self.allowance = allowance
    }
}
