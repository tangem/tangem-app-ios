//
//  CollectiblesVaultInfoTests.swift
//  TangemCollectiblesTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import TangemCollectibles

@Suite("CollectiblesVaultInfo")
struct CollectiblesVaultInfoTests {
    @Test("The remaining daily budget follows the program's day bucket, not a raw subtraction", arguments: Self.budgetArguments)
    func remainingTodayFollowsDayBucket(dayIndex: Int64, remaining: UInt64) {
        let vaultInfo = CollectiblesVaultInfo(
            vaultAddress: "aBRHcE97NY1MjVqGbc2LX2cApfPg9r5h5T1KNZS93oA",
            sessionKey: Data(repeating: 0xBB, count: 32),
            perSpinCap: 300_000_000,
            dailyCap: 900,
            spentToday: 250,
            dayIndex: dayIndex
        )

        #expect(vaultInfo.remainingToday(now: Constants.noonOfDay20690) == remaining)
    }
}

// MARK: - Arguments

extension CollectiblesVaultInfoTests {
    static let budgetArguments: [(dayIndex: Int64, remaining: UInt64)] = [
        (dayIndex: 20_690, remaining: 650),
        (dayIndex: 20_689, remaining: 900),
    ]
}

// MARK: - Helpers

private extension CollectiblesVaultInfoTests {
    enum Constants {
        static let noonOfDay20690 = Date(timeIntervalSince1970: 20_690 * 86_400 + 12 * 3_600)
    }
}
