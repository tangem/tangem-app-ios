//
//  GlowRingSnapshotTests.swift
//  TangemSnapshotTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SnapshotTesting
import TangemSnapshotTestSupport
import Testing

@MainActor
@Suite("GlowRing snapshots", .serialized, .snapshots(record: .fromEnvironment))
struct GlowRingSnapshotTests {
    @Test(arguments: GlowRingSnapshotScenario.allCases)
    func glowRing(_ scenario: GlowRingSnapshotScenario) {
        assertSnapshots(of: scenario)
    }
}
