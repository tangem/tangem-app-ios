//
//  CheckmarkSnapshotTests.swift
//  TangemSnapshotTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SnapshotTesting
import TangemSnapshotTestSupport
import Testing

@MainActor
@Suite("Checkmark snapshots", .serialized, .snapshots(record: .fromEnvironment))
struct CheckmarkSnapshotTests {
    @Test(arguments: CheckmarkSnapshotScenario.allCases)
    func checkmark(_ scenario: CheckmarkSnapshotScenario) {
        assertSnapshots(of: scenario)
    }
}
