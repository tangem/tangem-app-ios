//
//  ActionMessageSnapshotTests.swift
//  TangemSnapshotTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SnapshotTesting
import TangemSnapshotTestSupport
import Testing

@MainActor
@Suite("ActionMessage snapshots", .serialized, .snapshots(record: .fromEnvironment))
struct ActionMessageSnapshotTests {
    @Test(arguments: ActionMessageSnapshotScenario.allCases)
    func actionMessage(_ scenario: ActionMessageSnapshotScenario) {
        assertSnapshots(of: scenario)
    }
}
