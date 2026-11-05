//
//  ButtonSnapshotTests.swift
//  TangemSnapshotTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SnapshotTesting
import TangemSnapshotTestSupport
import Testing

@MainActor
@Suite("Button snapshots", .serialized, .snapshots(record: .fromEnvironment))
struct ButtonSnapshotTests {
    @Test(arguments: ButtonSnapshotScenario.allCases)
    func button(_ scenario: ButtonSnapshotScenario) {
        assertSnapshots(of: scenario)
    }
}
