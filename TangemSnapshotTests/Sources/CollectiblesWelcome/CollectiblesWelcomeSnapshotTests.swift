//
//  CollectiblesWelcomeSnapshotTests.swift
//  TangemSnapshotTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SnapshotTesting
import TangemSnapshotTestSupport
import Testing

@MainActor
@Suite("Collectibles welcome snapshots", .serialized, .snapshots(record: .fromEnvironment))
struct CollectiblesWelcomeSnapshotTests {
    @Test(arguments: CollectiblesWelcomeSnapshotScenario.allCases)
    func collectiblesWelcome(_ scenario: CollectiblesWelcomeSnapshotScenario) {
        assertSnapshots(of: scenario)
    }
}
