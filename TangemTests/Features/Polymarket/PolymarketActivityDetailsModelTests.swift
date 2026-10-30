//
//  PolymarketActivityDetailsModelTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemLocalization
import TangemPolymarket
import TangemPolymarketUI
@testable import Tangem

@Suite("Polymarket history details")
struct PolymarketActivityDetailsModelTests {
    @Test("The details headline carries the same signed amount as the row", arguments: [
        HeadlineCase(type: .buy, result: nil),
        HeadlineCase(type: .sell, result: nil),
        HeadlineCase(type: .deposit, result: nil),
        HeadlineCase(type: .withdraw, result: nil),
        HeadlineCase(type: .redeem, result: nil),
    ])
    func headlineMatchesTheRow(headlineCase: HeadlineCase) {
        let record = PolymarketActivityRecord.make(type: headlineCase.type, result: headlineCase.result)

        let details = PolymarketActivityDetailsView.Model.make(record: record)
        let row = PolymarketActivityRow.Model.make(record: record)

        #expect(details.headlines == [row.amount])
    }

    @Test("A won claim shows the result above the same signed amount as the row")
    func wonClaim() {
        let record = PolymarketActivityRecord.make(type: .redeem, result: .won)

        let details = PolymarketActivityDetailsView.Model.make(record: record)

        #expect(details.headlines == ["Your Prediction Won", PolymarketActivityRow.Model.make(record: record).amount])
    }

    @Test("A split claim puts the unsigned amount into its title")
    func splitClaim() {
        let details = PolymarketActivityDetailsView.Model.make(record: .make(type: .redeem, result: .split))

        #expect(details.headlines == [Localization.predictionPositionResultSplitTitle(PolymarketOrderFormatter.money(5))])
    }

    @Test("A lost claim shows no amount")
    func lostClaim() {
        let details = PolymarketActivityDetailsView.Model.make(record: .make(type: .redeem, result: .lost))

        #expect(details.headlines == ["Your Prediction Loss"])
    }
}

extension PolymarketActivityDetailsModelTests {
    struct HeadlineCase: Sendable, CustomTestStringConvertible {
        let type: PolymarketActivityType
        let result: PolymarketRedeemResult?

        var testDescription: String { "\(type)" }
    }
}

// MARK: - Helpers

private extension PolymarketActivityRecord {
    static func make(type: PolymarketActivityType, result: PolymarketRedeemResult?) -> PolymarketActivityRecord {
        PolymarketActivityRecord(
            id: "1",
            type: type,
            occurredAt: Date(timeIntervalSince1970: 0),
            amount: 5,
            transactionHash: nil,
            market: nil,
            order: nil,
            redeemResult: result
        )
    }
}
