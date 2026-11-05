//
//  EarnCalculatorSnapshotTests.swift
//  TangemSnapshotTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SnapshotTesting
import TangemSnapshotTestSupport
import Testing

@MainActor
@Suite("Earn calculator snapshots", .serialized, .snapshots(record: .fromEnvironment))
struct EarnCalculatorSnapshotTests {
    @Test(arguments: EarnCalculatorSnapshotScenario.allCases)
    func earnCalculator(_ scenario: EarnCalculatorSnapshotScenario) {
        assertSnapshots(of: scenario)
    }
}
