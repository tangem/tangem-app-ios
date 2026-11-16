//
//  LendingDepositProjectionTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("Lending deposit projection")
struct LendingDepositProjectionTests {
    private let sut = LendingDepositProjection(
        currentApy: Decimal(55) / 1000,
        performanceFee: Decimal(15) / 100,
        currencyCode: "USD",
        locale: Locale(identifier: "en_US")
    )

    @Test("Projected earnings are the deposit's fiat value a year at the APY net of the performance fee")
    func yearlyEarnings() {
        #expect(sut.yearlyEarnings(fiatAmount: 800) == "~$37/year")
    }

    @Test("Projected earnings under a dollar keep their cents")
    func smallYearlyEarnings() {
        #expect(sut.yearlyEarnings(fiatAmount: 5) == "~$0.23/year")
    }

    @Test("Projected earnings that round up to a dollar show as whole dollars")
    func earningsRoundingUpToADollar() {
        #expect(sut.yearlyEarnings(fiatAmount: Decimal(213) / 10) == "~$1/year")
    }

    @Test("The APY shows up to two decimals and the performance fee up to one, both with no space before the sign")
    func rates() {
        #expect(sut.currentApy == "5.5%")
        #expect(sut.performanceFee == "15%")
    }

    @Test("The performance fee has one decimal, as on the product page")
    func performanceFeeMatchesProductPage() {
        let projection = LendingDepositProjection(
            currentApy: Decimal(55) / 1000,
            performanceFee: Decimal(1275) / 10000,
            currencyCode: "USD",
            locale: Locale(identifier: "en_US")
        )

        #expect(projection.performanceFee == "12.8%")
    }
}
