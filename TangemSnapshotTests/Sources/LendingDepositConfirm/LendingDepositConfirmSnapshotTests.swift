//
//  LendingDepositConfirmSnapshotTests.swift
//  TangemSnapshotTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemSnapshotTestSupport
import Testing

@MainActor
@Suite("Lending deposit confirm snapshots", .serialized, .snapshots(record: .fromEnvironment))
struct LendingDepositConfirmSnapshotTests {
    @Test(arguments: LendingDepositConfirmSnapshotScenario.allCases)
    func lendingDepositConfirm(_ scenario: LendingDepositConfirmSnapshotScenario) {
        assertSnapshots(of: scenario)
    }
}
