//
//  PolymarketActivityCSVTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemPolymarket
@testable import Tangem

@Suite("Polymarket history CSV")
struct PolymarketActivityCSVTests {
    @Test("Money that left the account is written with a minus")
    func outgoingIsNegative() throws {
        let line = try #require(lines(for: [.make(type: .withdraw, amount: 5)]).last)

        #expect(line.contains("\"-5\""))
    }

    @Test("Money that came in is written as is")
    func incomingIsPositive() throws {
        let line = try #require(lines(for: [.make(type: .deposit, amount: 5)]).last)

        #expect(line.contains("\"5\""))
        #expect(!line.contains("\"-5\""))
    }

    @Test("Quotes are doubled and formulas are defused in market titles")
    func escapesText() throws {
        let line = try #require(lines(for: [.make(type: .buy, amount: 1, title: "=HYPERLINK(\"x\")")]).last)

        #expect(line.contains("\"'=HYPERLINK(\"\"x\"\")\""))
    }

    @Test("Every record gets a line under the header")
    func lineCount() {
        #expect(lines(for: [.make(type: .buy, amount: 1), .make(type: .sell, amount: 2)]).count == 3)
    }
}

// MARK: - Helpers

private extension PolymarketActivityCSVTests {
    func lines(for records: [PolymarketActivityRecord]) -> [String] {
        PolymarketActivityCSV.make(records: records).components(separatedBy: "\r\n")
    }
}

private extension PolymarketActivityRecord {
    static func make(type: PolymarketActivityType, amount: Decimal, title: String? = nil) -> PolymarketActivityRecord {
        PolymarketActivityRecord(
            id: UUID().uuidString,
            type: type,
            occurredAt: Date(timeIntervalSince1970: 0),
            amount: amount,
            transactionHash: nil,
            market: title.map {
                PolymarketActivityMarket(
                    conditionId: "c",
                    outcomeIndex: 0,
                    shares: 1,
                    outcome: "Yes",
                    marketId: nil,
                    slug: nil,
                    title: $0,
                    iconURL: nil,
                    imageURL: nil,
                    endDate: nil,
                    isNegRisk: false,
                    event: nil
                )
            },
            order: nil,
            redeemResult: nil
        )
    }
}
