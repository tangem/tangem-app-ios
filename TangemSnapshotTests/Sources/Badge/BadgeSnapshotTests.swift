//
//  BadgeSnapshotTests.swift
//  TangemSnapshotTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SnapshotTesting
import TangemSnapshotTestSupport
import Testing

@MainActor
@Suite("Badge snapshots", .serialized, .snapshots(record: .fromEnvironment))
struct BadgeSnapshotTests {
    @Test(arguments: BadgeSnapshotScenario.allCases)
    func badge(_ scenario: BadgeSnapshotScenario) {
        assertSnapshots(of: scenario)
    }
}
