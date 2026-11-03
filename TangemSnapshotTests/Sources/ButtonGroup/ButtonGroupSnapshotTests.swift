//
//  ButtonGroupSnapshotTests.swift
//  TangemSnapshotTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemSnapshotTestSupport
import Testing

@MainActor
@Suite("ButtonGroup snapshots", .serialized, .snapshots(record: .fromEnvironment))
struct ButtonGroupSnapshotTests {
    @Test(arguments: ButtonGroupSnapshotScenario.allCases)
    func buttonGroup(_ scenario: ButtonGroupSnapshotScenario) {
        assertSnapshots(of: scenario)
    }
}
