//
//  PolymarketPriceFormatterTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("Polymarket price display")
struct PolymarketPriceFormatterTests {
    @Test("A price under the lowest tenth of a cent is held at it rather than shown as nothing")
    func aPriceUnderTheFloorIsHeldAtTheFloor() {
        #expect(PolymarketPriceFormatter.cents(probability("0.0003")) == PolymarketPriceFormatter.cents(probability("0.001")))
    }

    @Test("A price over the highest tenth of a cent is held at it rather than shown as certainty")
    func aPriceOverTheCeilingIsHeldAtTheCeiling() {
        #expect(PolymarketPriceFormatter.cents(probability("0.9996")) == PolymarketPriceFormatter.cents(probability("0.999")))
    }

    @Test("A resolved market keeps the certainty it has earned", arguments: ["0", "1"])
    func aResolvedMarketKeepsItsCertainty(_ value: String) {
        let probability = probability(value)

        #expect(PolymarketPriceFormatter.cents(probability, isResolved: true) != PolymarketPriceFormatter.cents(probability))
    }

    @Test("A whole number of cents drops the tenth")
    func aWholeNumberOfCentsDropsTheTenth() {
        #expect(!hasFraction(PolymarketPriceFormatter.cents(probability("0.74"))))
    }

    @Test("A tenth of a cent survives")
    func aTenthOfACentSurvives() {
        #expect(hasFraction(PolymarketPriceFormatter.cents(probability("0.746"))))
    }

    @Test("Half a hundredth of a cent rounds away from zero")
    func halfAHundredthRoundsUp() {
        #expect(PolymarketPriceFormatter.cents(probability("0.7445")) == PolymarketPriceFormatter.cents(probability("0.745")))
    }

    @Test("The feed reads a probability as a whole percent")
    func theFeedReadsAWholePercent() {
        #expect(!hasFraction(PolymarketPriceFormatter.percentText(probability("0.754"))))
    }
}

// MARK: - Fixtures

private extension PolymarketPriceFormatterTests {
    func probability(_ value: String) -> Decimal {
        Decimal(string: value)!
    }

    func hasFraction(_ text: String) -> Bool {
        text.contains(",") || text.contains(".")
    }
}
