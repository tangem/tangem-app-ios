//
//  FilterGroupSnapshotTests.swift
//  TangemSnapshotTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SnapshotTesting
import TangemSnapshotTestSupport
import Testing

@MainActor
@Suite("FilterGroup snapshots", .serialized, .snapshots(record: .fromEnvironment))
struct FilterGroupSnapshotTests {
    @Test(arguments: FilterGroupSnapshotScenario.allCases)
    func filterGroup(_ scenario: FilterGroupSnapshotScenario) {
        assertSnapshots(of: scenario)
    }
}
