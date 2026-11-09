//
//  PolymarketActivityRowModelTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemFoundation
import TangemPolymarket
import TangemPolymarketUI
@testable import Tangem

@Suite("Polymarket history row")
struct PolymarketActivityRowModelTests {
    @Test("Money that left the account is signed minus", arguments: [PolymarketActivityType.buy, .withdraw])
    func outgoingAmountIsNegative(type: PolymarketActivityType) {
        let model = PolymarketActivityRow.Model.make(record: .make(type: type, amount: 5))

        #expect(model.amount == "\(String.minusSign) \(PolymarketOrderFormatter.money(5))")
    }

    @Test("Money that reached the account is signed plus", arguments: [PolymarketActivityType.sell, .deposit, .redeem])
    func incomingAmountIsPositive(type: PolymarketActivityType) {
        let model = PolymarketActivityRow.Model.make(record: .make(type: type, amount: 5))

        #expect(model.amount == "\(String.plusSign) \(PolymarketOrderFormatter.money(5))")
    }

    @Test("An amount that rounds to zero cents shows a dash instead of a signed zero")
    func subCentAmountShowsADash() {
        let model = PolymarketActivityRow.Model.make(record: .make(type: .buy, amount: Decimal(string: "0.004")!))

        #expect(model.amount == "-")
    }

    @Test("Half a cent rounds up to a cent and keeps its sign")
    func halfCentAmountRoundsUp() {
        let model = PolymarketActivityRow.Model.make(record: .make(type: .buy, amount: Decimal(string: "0.005")!))

        #expect(model.amount == "\(String.minusSign) \(PolymarketOrderFormatter.money(Decimal(string: "0.01")!))")
    }
}

// MARK: - Helpers

private extension PolymarketActivityRecord {
    static func make(type: PolymarketActivityType, amount: Decimal) -> PolymarketActivityRecord {
        PolymarketActivityRecord(
            id: "1",
            type: type,
            occurredAt: Date(timeIntervalSince1970: 0),
            amount: amount,
            transactionHash: nil,
            market: nil,
            order: nil,
            redeemResult: nil
        )
    }
}
