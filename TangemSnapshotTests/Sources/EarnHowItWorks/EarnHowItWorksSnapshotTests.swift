//
//  EarnHowItWorksSnapshotTests.swift
//  TangemSnapshotTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SnapshotTesting
import TangemSnapshotTestSupport
import Testing

@MainActor
@Suite("Earn How it works snapshots", .serialized, .snapshots(record: .fromEnvironment))
struct EarnHowItWorksSnapshotTests {
    @Test(arguments: EarnHowItWorksSnapshotScenario.allCases)
    func earnHowItWorks(_ scenario: EarnHowItWorksSnapshotScenario) {
        assertSnapshots(of: scenario)
    }
}
