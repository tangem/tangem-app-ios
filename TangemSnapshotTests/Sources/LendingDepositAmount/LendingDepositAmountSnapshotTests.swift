//
//  LendingDepositAmountSnapshotTests.swift
//  TangemSnapshotTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SnapshotTesting
import TangemSnapshotTestSupport
import Testing

@MainActor
@Suite("Lending deposit amount snapshots", .serialized, .snapshots(record: .fromEnvironment))
struct LendingDepositAmountSnapshotTests {
    @Test(arguments: LendingDepositAmountSnapshotScenario.allCases)
    func lendingDepositAmount(_ scenario: LendingDepositAmountSnapshotScenario) {
        assertSnapshots(of: scenario)
    }
}
