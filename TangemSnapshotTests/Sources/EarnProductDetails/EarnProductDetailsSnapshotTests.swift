//
//  EarnProductDetailsSnapshotTests.swift
//  TangemSnapshotTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SnapshotTesting
import TangemSnapshotTestSupport
import Testing

@MainActor
@Suite("Earn product details snapshots", .serialized, .snapshots(record: .fromEnvironment))
struct EarnProductDetailsSnapshotTests {
    @Test(arguments: EarnProductDetailsSnapshotScenario.allCases)
    func earnProductDetails(_ scenario: EarnProductDetailsSnapshotScenario) {
        assertSnapshots(of: scenario)
    }
}
