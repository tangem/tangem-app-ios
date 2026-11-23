//
//  LendingWithdrawSnapshotTests.swift
//  TangemSnapshotTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemSnapshotTestSupport
import Testing

@MainActor
@Suite("Lending withdrawal snapshots", .serialized, .snapshots(record: .fromEnvironment))
struct LendingWithdrawSnapshotTests {
    @Test(arguments: LendingWithdrawSnapshotScenario.allCases)
    func lendingWithdraw(_ scenario: LendingWithdrawSnapshotScenario) {
        assertSnapshots(of: scenario)
    }
}
