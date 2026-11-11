//
//  EthYieldSnapshotTests.swift
//  TangemSnapshotTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SnapshotTesting
import TangemSnapshotTestSupport
import Testing

@MainActor
@Suite("ETH yield snapshots", .serialized, .snapshots(record: .fromEnvironment))
struct EthYieldSnapshotTests {
    @Test(arguments: EthYieldSnapshotScenario.allCases)
    func ethYield(_ scenario: EthYieldSnapshotScenario) {
        assertSnapshots(of: scenario)
    }
}
