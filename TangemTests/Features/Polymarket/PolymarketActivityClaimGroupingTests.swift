//
//  PolymarketActivityClaimGroupingTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemPolymarket
@testable import Tangem

@Suite("Polymarket history claim grouping")
struct PolymarketActivityClaimGroupingTests {
    @Test("Rows of one claim in one market become one row with the summed payout")
    func mergesOneClaim() {
        let records = [
            PolymarketActivityRecord.redeem(id: "1", hash: "0xabc", condition: "c1", outcome: 0, amount: 10, result: .won),
            PolymarketActivityRecord.redeem(id: "2", hash: "0xabc", condition: "c1", outcome: 1, amount: 0, result: .lost),
        ]

        let grouped = PolymarketActivityClaimGrouping.group(records)

        #expect(grouped.count == 1)
        #expect(grouped.first?.id == "1")
        #expect(grouped.first?.amount == 10)
        #expect(grouped.first?.redeemResult == .won)
        #expect(grouped.first?.market?.outcomeIndex == 0)
    }

    @Test("The paying outcome is kept even when it comes second")
    func keepsThePayingOutcome() {
        let records = [
            PolymarketActivityRecord.redeem(id: "1", hash: "0xabc", condition: "c1", outcome: 1, amount: 0, result: .lost),
            PolymarketActivityRecord.redeem(id: "2", hash: "0xabc", condition: "c1", outcome: 0, amount: 3, result: .split),
        ]

        let grouped = PolymarketActivityClaimGrouping.group(records)

        #expect(grouped.first?.redeemResult == .split)
        #expect(grouped.first?.market?.outcomeIndex == 0)
        #expect(grouped.first?.amount == 3)
    }

    @Test("A claim of losing outcomes only stays lost")
    func lostOnly() {
        let records = [
            PolymarketActivityRecord.redeem(id: "1", hash: "0xabc", condition: "c1", outcome: 0, amount: 0, result: .lost),
            PolymarketActivityRecord.redeem(id: "2", hash: "0xabc", condition: "c1", outcome: 1, amount: 0, result: .lost),
        ]

        #expect(PolymarketActivityClaimGrouping.group(records).first?.redeemResult == .lost)
    }

    @Test("Rows without a transaction hash are never merged")
    func noHashNoMerge() {
        let records = [
            PolymarketActivityRecord.redeem(id: "1", hash: nil, condition: "c1", outcome: 0, amount: 1, result: .won),
            PolymarketActivityRecord.redeem(id: "2", hash: nil, condition: "c1", outcome: 1, amount: 0, result: .lost),
        ]

        #expect(PolymarketActivityClaimGrouping.group(records).map(\.id) == ["1", "2"])
    }

    @Test("Different markets in one transaction stay apart")
    func differentMarkets() {
        let records = [
            PolymarketActivityRecord.redeem(id: "1", hash: "0xabc", condition: "c1", outcome: 0, amount: 1, result: .won),
            PolymarketActivityRecord.redeem(id: "2", hash: "0xabc", condition: "c2", outcome: 0, amount: 2, result: .won),
        ]

        #expect(PolymarketActivityClaimGrouping.group(records).map(\.id) == ["1", "2"])
    }

    @Test("A claim split across two pages merges once the second page arrives")
    func mergesAcrossPages() {
        let firstPage = [
            PolymarketActivityRecord.redeem(id: "1", hash: "0xabc", condition: "c1", outcome: 0, amount: 4, result: .won),
        ]
        let secondPage = [
            PolymarketActivityRecord.redeem(id: "2", hash: "0xABC", condition: "c1", outcome: 1, amount: 0, result: .lost),
            PolymarketActivityRecord.redeem(id: "3", hash: "0xdef", condition: "c9", outcome: 0, amount: 1, result: .won),
        ]

        #expect(PolymarketActivityClaimGrouping.group(firstPage).count == 1)

        let grouped = PolymarketActivityClaimGrouping.group(firstPage + secondPage)

        #expect(grouped.map(\.id) == ["1", "3"])
        #expect(grouped.first?.amount == 4)
    }

    @Test("Other kinds of rows pass through untouched and keep their order")
    func otherRowsUntouched() {
        let records = [
            PolymarketActivityRecord.withdraw(id: "w", hash: "0xabc"),
            PolymarketActivityRecord.redeem(id: "1", hash: "0xabc", condition: "c1", outcome: 0, amount: 1, result: .won),
        ]

        #expect(PolymarketActivityClaimGrouping.group(records).map(\.id) == ["w", "1"])
    }
}

// MARK: - Helpers

private extension PolymarketActivityRecord {
    static func redeem(
        id: String,
        hash: String?,
        condition: String,
        outcome: Int,
        amount: Decimal,
        result: PolymarketRedeemResult
    ) -> PolymarketActivityRecord {
        PolymarketActivityRecord(
            id: id,
            type: .redeem,
            occurredAt: Date(timeIntervalSince1970: 0),
            amount: amount,
            transactionHash: hash,
            market: PolymarketActivityMarket(
                conditionId: condition,
                outcomeIndex: outcome,
                shares: amount,
                outcome: outcome == 0 ? "Yes" : "No",
                marketId: nil,
                slug: nil,
                title: "Market \(condition)",
                iconURL: nil,
                imageURL: nil,
                endDate: nil,
                isNegRisk: false,
                event: nil
            ),
            order: nil,
            redeemResult: result
        )
    }

    static func withdraw(id: String, hash: String?) -> PolymarketActivityRecord {
        PolymarketActivityRecord(
            id: id,
            type: .withdraw,
            occurredAt: Date(timeIntervalSince1970: 0),
            amount: 5,
            transactionHash: hash,
            market: nil,
            order: nil,
            redeemResult: nil
        )
    }
}
