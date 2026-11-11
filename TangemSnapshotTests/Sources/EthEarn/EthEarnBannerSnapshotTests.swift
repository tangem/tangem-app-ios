//
//  EthEarnBannerSnapshotTests.swift
//  TangemSnapshotTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SnapshotTesting
import TangemSnapshotTestSupport
import Testing

@MainActor
@Suite("ETH Earn banner snapshots", .serialized, .snapshots(record: .fromEnvironment))
struct EthEarnBannerSnapshotTests {
    @Test(arguments: EthEarnBannerSnapshotScenario.allCases)
    func earnBanner(_ scenario: EthEarnBannerSnapshotScenario) {
        assertSnapshots(of: scenario)
    }
}
