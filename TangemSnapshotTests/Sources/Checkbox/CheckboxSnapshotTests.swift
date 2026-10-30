//
//  CheckboxSnapshotTests.swift
//  TangemSnapshotTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SnapshotTesting
import TangemSnapshotTestSupport
import Testing

@MainActor
@Suite("Checkbox snapshots", .serialized, .snapshots(record: .fromEnvironment))
struct CheckboxSnapshotTests {
    @Test(arguments: CheckboxSnapshotScenario.allCases)
    func checkbox(_ scenario: CheckboxSnapshotScenario) {
        assertSnapshots(of: scenario)
    }
}
