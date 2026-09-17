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
    @Test("Base units read back as shares, priced to the cent")
    func readsSizesBackInHumanUnits() {
        let record = PolymarketOrderRecord(
            status: .matched,
            originalSize: 10_000_000,
            matchedSize: 7_000_000,
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

    @Test("A status this build does not know is not mistaken for a match")
    func unknownStatusIsNotAMatch() {
        #expect(PolymarketOrderRecordStatus(rawValue: "ORDER_STATUS_SOMETHING_NEW") == nil)
    }
}
