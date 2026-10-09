//
//  SendAnalyticsHelperSlippageTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("SendAnalyticsHelper — slippage parameter")
struct SendAnalyticsHelperSlippageTests {
    @Test(
        "Reports the slippage fraction as a percent number with up to two digits",
        arguments: [
            (slippage: Decimal(string: "0.003")!, expected: "0.3"),
            (slippage: Decimal(string: "0.0011")!, expected: "0.11"),
            (slippage: Decimal(string: "0.02")!, expected: "2"),
            (slippage: Decimal(0.003), expected: "0.3"),
        ]
    )
    func formatsSlippage(slippage: Decimal, expected: String) {
        #expect(SendAnalyticsHelper.makeAnalyticsSlippage(slippage) == expected)
    }
}
