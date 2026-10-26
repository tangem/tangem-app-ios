//
//  YieldModePromoAnalyticsLoggerTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("CommonYieldModePromoAnalyticsLogger")
struct YieldModePromoAnalyticsLoggerTests {
    @Test(
        "APY is sent as a percent with two decimals, without locale or a percent sign",
        arguments: [
            (Decimal(string: "0.092")!, "9.20"),
            (Decimal(string: "0.061249")!, "6.12"),
            (Decimal(string: "0.0269")!, "2.69"),
            (Decimal(string: "0.000125")!, "0.01"),
            (Decimal(string: "1.23456")!, "123.46"),
        ]
    )
    func formatsAPY(apy: Decimal, expected: String) {
        #expect(CommonYieldModePromoAnalyticsLogger.formatAPY(apy) == expected)
    }
}
