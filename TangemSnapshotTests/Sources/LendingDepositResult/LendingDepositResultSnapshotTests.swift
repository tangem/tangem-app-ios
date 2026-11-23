//
//  LendingDepositResultSnapshotTests.swift
//  TangemSnapshotTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemSnapshotTestSupport
import Testing

@MainActor
@Suite("Lending deposit result snapshots", .serialized, .snapshots(record: .fromEnvironment))
struct LendingDepositResultSnapshotTests {
    @Test(arguments: LendingDepositResultSnapshotScenario.allCases)
    func lendingDepositResult(_ scenario: LendingDepositResultSnapshotScenario) {
        assertSnapshots(of: scenario)
    }
}
