//
//  CompoundingEarnCalculatorProjectorTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemFoundation
@testable import Tangem

@Suite("CompoundingEarnCalculatorProjector")
struct CompoundingEarnCalculatorProjectorTests {
    typealias SUT = CompoundingEarnCalculatorProjector

    @Test("Monthly compounding at net APY matches the reference projection to the cent")
    func referenceProjection() {
        let input = EarnCalculatorInput(initialBalance: 2500, monthlyTopUp: 500, horizon: .threeYears)

        let projection = SUT(apy: 0.0468, performanceFee: 0).project(input)

        #expect(projection.finalBalance.rounded(scale: 2, roundingMode: .plain) == Decimal(string: "22124.34"))
        #expect(projection.earned == projection.finalBalance - 20500)
    }

    @Test("Without top-ups a year grows by exactly the net APY")
    func yearGrowsByNetApy() {
        let input = EarnCalculatorInput(initialBalance: 1000, monthlyTopUp: 0, horizon: .oneYear)

        let projection = SUT(apy: 0.055, performanceFee: 0.15).project(input)

        #expect(projection.finalBalance.rounded(scale: 2, roundingMode: .plain) == Decimal(string: "1046.75"))
    }

    @Test("The performance fee is taken out of the APY before compounding")
    func performanceFeeReducesApy() {
        let input = EarnCalculatorInput(initialBalance: 800, monthlyTopUp: 0, horizon: .oneYear)

        let projection = SUT(apy: 0.055, performanceFee: 0.15).project(input)

        #expect(projection.earned.rounded(scale: 2, roundingMode: .plain) == Decimal(string: "37.4"))
    }

    @Test("A top-up arrives at the end of the month and earns nothing in that month")
    func topUpAtMonthEnd() {
        let input = EarnCalculatorInput(initialBalance: 0, monthlyTopUp: 100, horizon: .sixMonths)

        let firstMonth = SUT(apy: 0.05, performanceFee: 0).project(input).points.first

        #expect(firstMonth?.balance == 100)
        #expect(firstMonth?.earned == 0)
    }

    @Test("Zero APY earns nothing")
    func zeroApy() {
        let input = EarnCalculatorInput(initialBalance: 2500, monthlyTopUp: 500, horizon: .fiveYears)

        let projection = SUT(apy: 0, performanceFee: 0.15).project(input)

        #expect(projection.finalBalance == 32500)
        #expect(projection.earned == 0)
    }

    @Test("Every horizon gets one point per month", arguments: EarnCalculatorHorizon.allCases)
    func onePointPerMonth(horizon: EarnCalculatorHorizon) {
        let input = EarnCalculatorInput(initialBalance: 2500, monthlyTopUp: 500, horizon: horizon)

        let months = SUT(apy: 0.05, performanceFee: 0.15).project(input).points.map(\.month)

        #expect(months == Array(1 ... horizon.months))
    }
}
