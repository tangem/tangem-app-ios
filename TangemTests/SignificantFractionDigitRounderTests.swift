//
//  SignificantFractionDigitRounderTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("SignificantFractionDigitRounder")
struct SignificantFractionDigitRounderTests {
    /// The rounded `Decimal` is compared through its `Double` representation, hence the tolerance.
    private static let accuracy = 0.000000000000000001

    @Test(
        "Rounding down keeps the leading significant fraction digit",
        arguments: [
            (0.00, 0.00),
            (0.00000001, 0.00000001),
            (0.00002345, 0.00002),
            (0.000029, 0.00002),
            (0.000000000000000001, 0.000000000000000001),
            (0.0000000000000000001, 0.00),
            (1.00002345, 1.00),
            (1.45002345, 1.45),
        ] as [(Double, Double)]
    )
    func roundsDownToTheSignificantFractionDigit(value: Double, expectedValue: Double) {
        let rounder = SignificantFractionDigitRounder(roundingMode: .down)

        let roundedValue = rounder.round(value: Decimal(floatLiteral: value))
        let roundedDoubleValue = NSDecimalNumber(decimal: roundedValue).doubleValue

        #expect(abs(roundedDoubleValue - expectedValue) <= Self.accuracy)
    }
}
