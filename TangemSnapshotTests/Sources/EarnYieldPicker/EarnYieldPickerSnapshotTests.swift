//
//  EarnYieldPickerSnapshotTests.swift
//  TangemSnapshotTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SnapshotTesting
import TangemSnapshotTestSupport
import Testing

@MainActor
@Suite("Earn yield picker snapshots", .serialized, .snapshots(record: .fromEnvironment))
struct EarnYieldPickerSnapshotTests {
    @Test(arguments: EarnYieldPickerSnapshotScenario.allCases)
    func earnYieldPicker(_ scenario: EarnYieldPickerSnapshotScenario) {
        assertSnapshots(of: scenario)
    }
}
