//
//  StakingManagerStateRepositoryTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemFoundation
@testable import TangemStaking

struct StakingManagerStateRepositoryTests {
    @Test
    func notEnabledStateClearsCachedStake() throws {
        let file = TestFile()
        defer { file.remove() }

        let repository = CommonStakingManagerStateRepository(
            stakingWallet: StakingWallet(item: .ethereum, address: "0x0000000000000000000000000000000000000001", publicKey: Data([0x01])),
            storage: CachesDirectoryStorage(file: file)
        )

        repository.storeState(.staked(.init(balances: [], yieldInfo: makeYieldInfo(), canStakeMore: false)))
        try #require(repository.state() != nil)

        repository.storeState(.notEnabled)

        #expect(repository.state() == nil)
    }
}

// MARK: - Helpers

private extension StakingManagerStateRepositoryTests {
    struct TestFile: CachesDirectoryStorage.File {
        let name = "staking_manager_state_repository_tests_\(UUID().uuidString)"

        func remove() {
            let url = FileManager.default
                .urls(for: .cachesDirectory, in: .userDomainMask)[0]
                .appendingPathComponent(name)
                .appendingPathExtension("json")

            try? FileManager.default.removeItem(at: url)
        }
    }

    func makeYieldInfo() -> StakingYieldInfo {
        StakingYieldInfo(
            id: "ethereum",
            isAvailable: true,
            rewardType: .apy,
            rewardRateValues: RewardRateValues(aprs: [], rewardRate: .zero),
            enterMinimumRequirement: .zero,
            exitMinimumRequirement: .zero,
            targets: [],
            preferredTargets: [],
            item: .ethereum,
            unbondingPeriod: .days(0),
            warmupPeriod: .days(0),
            rewardClaimingType: .auto,
            rewardScheduleType: .daily,
            rewardsIncludedInStake: true,
            maximumStakeAmount: nil
        )
    }
}
