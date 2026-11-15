//
//  LendingApyChartTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("Lending APY chart scale")
struct LendingApyChartTests {
    @Test("Four round ticks reach a quarter above the highest rate", arguments: [
        (0.0146, [0, 0.01, 0.02, 0.03]),
        (0.0055, [0, 0.0025, 0.005, 0.0075]),
        (0.042, [0, 0.02, 0.04, 0.06]),
        (0.062, [0, 0.03, 0.06, 0.09]),
        (0.09, [0, 0.04, 0.08, 0.12]),
    ])
    func ticks(peak: Double, expected: [Double]) {
        let ticks = LendingApyChart.fittedTicks(peak: peak)

        #expect(ticks.count == expected.count)
        #expect(zip(ticks, expected).allSatisfy { abs($0 - $1) < 1e-12 })
        #expect((ticks.last ?? 0) >= peak * 1.25)
    }

    @Test("Without a positive rate there is nothing to fit")
    func noRate() {
        #expect(LendingApyChart.fittedTicks(peak: 0).isEmpty)
    }
}
