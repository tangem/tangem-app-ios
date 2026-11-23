//
//  GaslessMaxTokenFeeCalculatorTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BigInt
import Testing
@testable import Tangem

@Suite("Gasless max token fee")
struct GaslessMaxTokenFeeCalculatorTests {
    @Test("Without the Yield withdraw reserve the max fee is the fee rounded up to the smallest token unit")
    func feeRoundsUpWithoutReserve() {
        let fee = maxTokenFee(feeAmount: Decimal(505_481) / 10_000_000, keepsYieldWithdrawReserve: false)

        #expect(fee == BigUInt(50_549))
    }

    @Test("With the Yield withdraw reserve the max fee keeps five smallest units for Aave rounding")
    func yieldWithdrawKeepsRoundingReserve() {
        let fee = maxTokenFee(feeAmount: Decimal(505_481) / 10_000_000, keepsYieldWithdrawReserve: true)

        #expect(fee == BigUInt(50_544))
    }

    @Test("A fee one unit above the reserve leaves one unit")
    func feeJustAboveReserveLeavesOneUnit() {
        let fee = maxTokenFee(feeAmount: Decimal(6) / 1_000_000, keepsYieldWithdrawReserve: true)

        #expect(fee == BigUInt(1))
    }

    @Test(
        "A fee the reserve would take whole stays unchanged",
        arguments: [false, true],
        [(Decimal(0), BigUInt(0)), (Decimal(5) / 1_000_000, BigUInt(5))]
    )
    func feeWithinReserveStaysUnchanged(keepsYieldWithdrawReserve: Bool, feeCase: (amount: Decimal, expected: BigUInt)) {
        let fee = maxTokenFee(feeAmount: feeCase.amount, keepsYieldWithdrawReserve: keepsYieldWithdrawReserve)

        #expect(fee == feeCase.expected)
    }
}

// MARK: - Helpers

private extension GaslessMaxTokenFeeCalculatorTests {
    func maxTokenFee(feeAmount: Decimal, keepsYieldWithdrawReserve: Bool) -> BigUInt? {
        GaslessMaxTokenFeeCalculator.maxTokenFee(
            feeAmount: feeAmount,
            decimalValue: 1_000_000,
            keepsYieldWithdrawReserve: keepsYieldWithdrawReserve
        )
    }
}
