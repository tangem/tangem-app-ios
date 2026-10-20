//
//  PolymarketRedeemService.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public protocol PolymarketRedeemService {
    func calls(for request: PolymarketRedeemCallRequest) async throws(PolymarketRedeemError) -> [PolymarketRelayedBatch.Call]

    func submit(_ batch: PolymarketRelayedBatch) async throws(PolymarketRedeemError) -> PolymarketRedeemRecord

    func record(ofClaim transactionId: String) async throws(PolymarketRedeemError) -> PolymarketRedeemRecord
}
