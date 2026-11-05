//
//  LendingPositionSnapshotTests.swift
//  TangemSnapshotTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SnapshotTesting
import TangemSnapshotTestSupport
import Testing

@MainActor
@Suite("Lending position snapshots", .serialized, .snapshots(record: .fromEnvironment))
struct LendingPositionSnapshotTests {
    @Test(arguments: LendingPositionSnapshotScenario.allCases)
    func lendingPosition(_ scenario: LendingPositionSnapshotScenario) {
        assertSnapshots(of: scenario)
    }
}
