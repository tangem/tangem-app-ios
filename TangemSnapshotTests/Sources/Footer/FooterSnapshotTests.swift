//
//  FooterSnapshotTests.swift
//  TangemSnapshotTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SnapshotTesting
import TangemSnapshotTestSupport
import Testing

@MainActor
@Suite("Footer snapshots", .serialized, .snapshots(record: .fromEnvironment))
struct FooterSnapshotTests {
    @Test(arguments: FooterSnapshotScenario.allCases)
    func footer(_ scenario: FooterSnapshotScenario) {
        assertSnapshots(of: scenario)
    }
}
