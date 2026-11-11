//
//  EarnGetTokenSheetSnapshotTests.swift
//  TangemSnapshotTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SnapshotTesting
import TangemSnapshotTestSupport
import Testing

@MainActor
@Suite("Earn Get token sheet snapshots", .serialized, .snapshots(record: .fromEnvironment))
struct EarnGetTokenSheetSnapshotTests {
    @Test(arguments: EarnGetTokenSheetSnapshotScenario.allCases)
    func earnGetTokenSheet(_ scenario: EarnGetTokenSheetSnapshotScenario) {
        assertSnapshots(of: scenario)
    }
}
