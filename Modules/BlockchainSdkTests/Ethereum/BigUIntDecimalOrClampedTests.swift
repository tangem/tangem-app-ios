//
//  BigUIntDecimalOrClampedTests.swift
//  BlockchainSdkTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BigInt
import Foundation
import Testing
@testable import BlockchainSdk

struct BigUIntDecimalOrClampedTests {
    @Test
    func matchesDecimalForNormalValues() {
        let value = BigUInt(21_000) * BigUInt(50_000_000_000) // 21000 gas × 50 gwei
        #expect(value.decimalOrClamped == value.decimal)
        #expect(value.decimalOrClamped == Decimal(string: "1050000000000000"))
    }

    @Test
    func doesNotTrapAboveUInt64Max() {
        // gasLimit × gasPrice that overflows UInt64 (> 1.8e19): Decimal(UInt64(feeWEI)) used to crash here.
        let feeWEI = BigUInt(30_000_000) * BigUInt(UInt64.max)
        let result = feeWEI.decimalOrClamped
        #expect(result > 0)
    }

    @Test
    func clampsValuesBeyondDecimalRange() {
        // Far beyond Decimal.greatestFiniteMagnitude (~3.4e38): still no trap, returns a finite positive value.
        let huge = BigUInt(10).power(60)
        #expect(huge.decimalOrClamped > 0)
    }
}
