//
//  ToastSnapshotTests.swift
//  TangemSnapshotTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemSnapshotTestSupport
import Testing

@MainActor
@Suite("Toast snapshots", .serialized, .snapshots(record: .fromEnvironment))
struct ToastSnapshotTests {
    @Test(arguments: ToastSnapshotScenario.allCases)
    func toast(_ scenario: ToastSnapshotScenario) {
        assertSnapshots(of: scenario)
    }
}
