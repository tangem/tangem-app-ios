//
//  EarnWithdrawalResultSnapshotTests.swift
//  TangemSnapshotTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SnapshotTesting
import TangemSnapshotTestSupport
import Testing

@MainActor
@Suite("Earn withdrawal result snapshots", .serialized, .snapshots(record: .fromEnvironment))
struct EarnWithdrawalResultSnapshotTests {
    @Test(arguments: EarnWithdrawalResultSnapshotScenario.allCases)
    func earnWithdrawalResult(_ scenario: EarnWithdrawalResultSnapshotScenario) {
        assertSnapshots(of: scenario)
    }
}
