//
//  PolymarketWithdrawing.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemPolymarket

protocol PolymarketWithdrawing: Sendable {
    func withdraw(amount: Decimal, to recipientAddress: String) async throws -> PolymarketWithdrawRecord
}
