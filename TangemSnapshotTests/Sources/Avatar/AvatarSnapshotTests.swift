//
//  AvatarSnapshotTests.swift
//  TangemSnapshotTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemSnapshotTestSupport
import Testing

@MainActor
@Suite("Avatar snapshots", .serialized, .snapshots(record: .fromEnvironment))
struct AvatarSnapshotTests {
    @Test(arguments: AvatarSnapshotScenario.allCases)
    func avatar(_ scenario: AvatarSnapshotScenario) {
        assertSnapshots(of: scenario)
    }
}
