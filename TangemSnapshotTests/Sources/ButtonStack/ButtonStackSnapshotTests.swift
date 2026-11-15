//
//  ButtonStackSnapshotTests.swift
//  TangemSnapshotTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemSnapshotTestSupport
import Testing

@MainActor
@Suite("ButtonStack snapshots", .serialized, .snapshots(record: .fromEnvironment))
struct ButtonStackSnapshotTests {
    @Test(arguments: ButtonStackSnapshotScenario.allCases)
    func buttonStack(_ scenario: ButtonStackSnapshotScenario) {
        assertSnapshots(of: scenario)
    }
}
