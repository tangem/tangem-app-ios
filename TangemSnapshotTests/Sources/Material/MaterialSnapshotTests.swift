//
//  MaterialSnapshotTests.swift
//  TangemSnapshotTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SnapshotTesting
import TangemSnapshotTestSupport
import Testing

@MainActor
@Suite("Material snapshots", .serialized, .snapshots(record: .fromEnvironment))
struct MaterialSnapshotTests {
    @Test(arguments: MaterialSnapshotScenario.allCases)
    func material(_ scenario: MaterialSnapshotScenario) {
        assertSnapshots(of: scenario)
    }
}
