//
//  TokenRowSnapshotTests.swift
//  TangemSnapshotTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SnapshotTesting
import TangemSnapshotTestSupport
import Testing

@MainActor
@Suite("TokenRow snapshots", .serialized, .snapshots(record: .fromEnvironment))
struct TokenRowSnapshotTests {
    @Test(arguments: TokenRowSnapshotScenario.allCases)
    func tokenRow(_ scenario: TokenRowSnapshotScenario) {
        assertSnapshots(of: scenario)
    }
}
