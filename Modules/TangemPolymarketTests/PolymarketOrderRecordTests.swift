//
//  PolymarketOrderRecordTests.swift
//  TangemPolymarketTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import TangemPolymarket

@Suite("Polymarket order record")
struct PolymarketOrderRecordTests {
    @Test("Sizes read back as the shares they already are, priced to the cent")
    func readsSizesBackInHumanUnits() {
        let record = PolymarketOrderRecord(
            status: .matched,
            originalSize: 10,
            matchedSize: 7,
            price: Decimal(string: "0.208")!
        )

        #expect(record.matchedShares == 7)
        #expect(record.executedAmount == Decimal(string: "1.46")!)
        #expect(!record.isFullyMatched)
    }

    @Test("A fill that took the whole order reads as full")
    func fullFillReadsAsFull() {
        let record = PolymarketOrderRecord(status: .matched, originalSize: 85, matchedSize: 85, price: Decimal(string: "0.5")!)

        #expect(record.isFullyMatched)
    }

    @Test("A filled order reports the money that actually left the account")
    func aFilledOrderReportsTheMoneySpent() {
        let record = PolymarketOrderRecord(
            status: .matched,
            originalSize: Decimal(string: "13.1578")!,
            matchedSize: Decimal(string: "13.888889")!,
            price: Decimal(string: "0.38")!
        )

        #expect(record.matchedShares == Decimal(string: "13.888889")!)
        #expect(record.executedAmount == Decimal(string: "5.28")!)
        #expect(record.isFullyMatched)
    }

    @Test("Dust rounds to nothing in money and is still a filled sale")
    func dustIsStillAFill() {
        let record = PolymarketOrderRecord(
            status: .matched,
            originalSize: Decimal(string: "0.4")!,
            matchedSize: Decimal(string: "0.4")!,
            price: Decimal(string: "0.01")!
        )

        let placement = PolymarketOrderPlacement.settled(record, orderId: "order", side: .sell)

        #expect(record.executedAmount == 0)
        #expect(!placement.isMatchedWithoutFill(side: .sell))
        #expect(placement.filledShares(side: .sell) == Decimal(string: "0.4")!)
    }

    @Test("A status this build does not know is not mistaken for a match")
    func unknownStatusIsNotAMatch() {
        #expect(PolymarketOrderRecordStatus(rawValue: "ORDER_STATUS_SOMETHING_NEW") == nil)
    }

    @Test(
        "The exchange's bare status names decode to the same cases as the contract's prefixed ones",
        arguments: [
            ("MATCHED", PolymarketOrderRecordStatus.matched),
            ("ORDER_STATUS_MATCHED", .matched),
            ("LIVE", .live),
            ("ORDER_STATUS_LIVE", .live),
            ("CANCELED", .canceled),
            ("CANCELED_MARKET_RESOLVED", .canceledMarketResolved),
            ("INVALID", .invalid),
        ]
    )
    func bareStatusNamesDecode(raw: String, expected: PolymarketOrderRecordStatus) throws {
        let decoded = try JSONDecoder().decode(PolymarketOrderRecordStatus.self, from: Data("\"\(raw)\"".utf8))

        #expect(decoded == expected)
    }

    @Test("A status neither spelling explains is unknown, not a verdict")
    func anUnreadableStatusDecodesAsUnknown() throws {
        let decoded = try JSONDecoder().decode(PolymarketOrderRecordStatus.self, from: Data("\"SOMETHING_NEW\"".utf8))

        #expect(decoded == .unknown)
    }
}
