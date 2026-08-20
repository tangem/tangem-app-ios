//
//  PeriodTests.swift
//  TangemStakingTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing
@testable import TangemStaking

@Suite("Period")
struct PeriodTests {
    @Test(
        "isZero reflects whether the seconds value is zero",
        arguments: [(0, true), (129600, false)]
    )
    func secondsIsZero(seconds: Int, expected: Bool) {
        #expect(Period.seconds(seconds).isZero == expected)
    }
}
