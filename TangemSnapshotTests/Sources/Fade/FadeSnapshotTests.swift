//
//  FadeSnapshotTests.swift
//  TangemSnapshotTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SnapshotTesting
import TangemSnapshotTestSupport
import Testing

@MainActor
@Suite("Fade snapshots", .serialized, .snapshots(record: .fromEnvironment))
struct FadeSnapshotTests {
    @Test(arguments: FadeSnapshotScenario.allCases)
    func fade(_ scenario: FadeSnapshotScenario) {
        assertSnapshots(of: scenario)
    }
}
