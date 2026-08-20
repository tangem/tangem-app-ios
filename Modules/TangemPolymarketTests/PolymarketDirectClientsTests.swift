//
//  PolymarketDirectClientsTests.swift
//  TangemPolymarketTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemFoundation
@testable import TangemPolymarket

@Suite("CLOB collateral amounts")
struct PolymarketCollateralAmountTests {
    @Test(
        "Amounts arrive in the smallest unit and are shifted by the collateral exponent",
        arguments: [
            ("0", Decimal(0)),
            ("1", Decimal(stringValue: "0.000001")!),
            ("1000000", Decimal(1)),
            ("40000000000", Decimal(40000)),
        ]
    )
    func amountIsShifted(rawValue: String, expected: Decimal) throws {
        let amount = try #require(CommonPolymarketCLOBService.collateralAmount(from: rawValue))

        #expect(amount == expected)
    }

    @Test("A max allowance stays exact rather than overflowing into a rounded double")
    func maxAllowanceIsReadable() throws {
        let maxUint256 = "115792089237316195423570985008687907853269984665640564039457584007913129639935"

        let amount = CommonPolymarketCLOBService.collateralAmount(from: maxUint256)

        #expect(amount != nil)
    }

    @Test("An unreadable amount is reported rather than defaulted to zero")
    func unreadableAmountIsRejected() {
        #expect(CommonPolymarketCLOBService.collateralAmount(from: "not-a-number") == nil)
    }
}
