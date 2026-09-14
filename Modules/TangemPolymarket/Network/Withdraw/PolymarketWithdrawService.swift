//
//  PolymarketWithdrawService.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public protocol PolymarketWithdrawService {
    func submit(_ batch: PolymarketRelayedBatch) async throws(PolymarketWithdrawError) -> PolymarketWithdrawRecord

    func record(ofWithdrawal transactionId: String) async throws(PolymarketWithdrawError) -> PolymarketWithdrawRecord
}
