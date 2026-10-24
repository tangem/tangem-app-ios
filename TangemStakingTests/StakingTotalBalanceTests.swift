//
//  StakingTotalBalanceTests.swift
//  TangemStakingTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import TangemStaking

struct StakingTotalBalanceTests {
    @Test("P2P total leaves out earned rewards because the staked amount already contains them")
    func p2pTotalExcludesEarnedRewards() throws {
        let staked = StakingManagerState.Staked(
            balances: makeBalances(),
            yieldInfo: try makeP2PYieldInfo(),
            canStakeMore: true
        )

        #expect(staked.totalBalance == Decimal(string: "8.5")!)
    }

    @Test("Total keeps rewards when they are held apart from the staked amount")
    func totalKeepsSeparateRewards() {
        let staked = StakingManagerState.Staked(
            balances: makeBalances(),
            yieldInfo: makeYieldInfo(rewardsIncludedInStake: false),
            canStakeMore: true
        )

        #expect(staked.totalBalance == Decimal(string: "11.75")!)
    }
}

// MARK: - Helpers

private extension StakingTotalBalanceTests {
    func makeBalances() -> [StakingBalance] {
        [
            makeBalance(amount: "5.5", type: .active),
            makeBalance(amount: "2", type: .unbonding(date: nil)),
            makeBalance(amount: "1", type: .unstaked),
            makeBalance(amount: "3.25", type: .rewards),
            makeBalance(amount: "4", type: .pending),
        ]
    }

    func makeBalance(amount: String, type: StakingBalanceType) -> StakingBalance {
        StakingBalance(
            item: .ethereum,
            amount: Decimal(string: amount)!,
            balanceType: type,
            targetType: .empty,
            inProgress: false,
            actions: []
        )
    }

    func makeP2PYieldInfo() throws -> StakingYieldInfo {
        let json = """
        {
            "network": "ethereum",
            "vaults": [
                {
                    "vaultAddress": "0x4c09BC47db288F998b33CD63BCc1b6ddCCe13F33",
                    "displayName": "Tangem Vault",
                    "apy": 3.1,
                    "baseApy": 3,
                    "capacity": null,
                    "totalAssets": "100",
                    "feePercent": 10,
                    "isPrivate": false,
                    "isGenesis": false,
                    "isSmoothingPool": false,
                    "isErc20": false,
                    "tokenName": null,
                    "tokenSymbol": null,
                    "createdAt": "2026-08-11T09:00:00Z"
                }
            ]
        }
        """

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let response = try decoder.decode(P2PDTO.Vaults.VaultsInfo.self, from: Data(json.utf8))

        return try P2PMapper().mapToYieldInfo(from: response, targetAmountInfos: [:])
    }

    func makeYieldInfo(rewardsIncludedInStake: Bool) -> StakingYieldInfo {
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
            rewardsIncludedInStake: rewardsIncludedInStake,
            maximumStakeAmount: nil
        )
    }
}
