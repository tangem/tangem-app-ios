//
//  PolymarketOrderFormatterTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemFoundation
@testable import Tangem

@Suite("Polymarket money formatting", .timeLimit(.minutes(1)))
struct PolymarketOrderFormatterTests {
    @Test(
        "Money is rounded to the cent, half a cent away from zero",
        arguments: [
            ("1.004", "1"),
            ("1.005", "1.01"),
            ("-1.005", "-1.01"),
            ("-0.004", "0"),
            ("0.005", "0.01"),
        ]
    )
    func displayedMoneyRoundsToTheCent(_ value: String, _ expected: String) throws {
        let value = try #require(Decimal(string: value))
        let expected = try #require(Decimal(string: expected))

        #expect(PolymarketOrderFormatter.displayedMoney(value) == expected)
    }

    @Test("Zero carries no sign")
    func zeroHasNoSign() {
        #expect(PolymarketOrderFormatter.signedMoney(0) == PolymarketOrderFormatter.money(0))
    }

    @Test("A loss or gain that rounds to zero carries no sign", arguments: ["-0.004", "0.004"])
    func amountRoundingToZeroHasNoSign(_ value: String) throws {
        let value = try #require(Decimal(string: value))

        #expect(PolymarketOrderFormatter.signedMoney(value) == PolymarketOrderFormatter.money(0))
    }

    @Test("A loss is shown with a minus and the rounded amount")
    func lossHasMinus() throws {
        let value = try #require(Decimal(string: "-1.005"))
        let rounded = try #require(Decimal(string: "1.01"))

        #expect(PolymarketOrderFormatter.signedMoney(value) == "\(String.minusSign) \(PolymarketOrderFormatter.money(rounded))")
    }

    @Test("A gain is shown with a plus and the rounded amount")
    func gainHasPlus() throws {
        let value = try #require(Decimal(string: "0.005"))
        let rounded = try #require(Decimal(string: "0.01"))

        #expect(PolymarketOrderFormatter.signedMoney(value) == "\(String.plusSign) \(PolymarketOrderFormatter.money(rounded))")
    }
}
