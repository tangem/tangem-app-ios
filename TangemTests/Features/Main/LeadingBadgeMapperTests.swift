//
//  LeadingBadgeMapperTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import TangemStaking
@testable import Tangem

@Suite("ETH row rate badge")
struct LeadingBadgeMapperTests {
    @Test("The badge shows the higher of the staking and lending rates, and follows the lending rate when it overtakes")
    func bestRate() throws {
        let staking = makeAvailableStaking(apy: Decimal(31) / 1000)

        let before = try rewards(LeadingBadgeMapper.mapRewards(stakingManagerState: staking, lendingApy: Decimal(24) / 1000))
        let after = try rewards(LeadingBadgeMapper.mapRewards(stakingManagerState: staking, lendingApy: Decimal(35) / 1000))

        #expect(before.rewardValue == formatted(Decimal(31) / 1000))
        #expect(after.rewardValue == formatted(Decimal(35) / 1000))
        #expect(after.type == .apy)
    }

    @Test("With staking unavailable the badge shows the lending rate")
    func stakingUnavailable() throws {
        let staking = StakingManagerState.temporaryUnavailable(makeStakingYieldInfo(apy: Decimal(31) / 1000))

        let info = try rewards(LeadingBadgeMapper.mapRewards(stakingManagerState: staking, lendingApy: Decimal(24) / 1000))

        #expect(info.rewardValue == formatted(Decimal(24) / 1000))
        #expect(info.type == .apy)
        #expect(!info.isActive)
    }

    @Test("Without a lending rate the badge is the staking badge it was before")
    func stakingOnly() throws {
        let staking = makeAvailableStaking(apy: Decimal(31) / 1000, rewardType: .apr)

        let info = try rewards(LeadingBadgeMapper.mapRewards(stakingManagerState: staking, lendingApy: nil))

        #expect(info.rewardValue == formatted(Decimal(31) / 1000))
        #expect(info.type == .apr)
    }

    @Test("A higher staking rate keeps its own reward type")
    func stakingWins() throws {
        let staking = makeAvailableStaking(apy: Decimal(4) / 100, rewardType: .apr)

        let info = try rewards(LeadingBadgeMapper.mapRewards(stakingManagerState: staking, lendingApy: Decimal(3) / 100))

        #expect(info.type == .apr)
        #expect(info.rewardValue == formatted(Decimal(4) / 100))
    }

    @Test("An active stake keeps showing the rate it earns")
    func activeStaking() throws {
        let staking = StakingManagerState.staked(
            .init(balances: [], yieldInfo: makeStakingYieldInfo(apy: Decimal(31) / 1000), canStakeMore: true)
        )

        let info = try rewards(LeadingBadgeMapper.mapRewards(stakingManagerState: staking, lendingApy: Decimal(35) / 1000))

        #expect(info.rewardValue == formatted(Decimal(31) / 1000))
        #expect(info.isActive)
    }

    @Test("No rate at all shows no badge")
    func noRate() {
        #expect(LeadingBadgeMapper.mapRewards(stakingManagerState: .notEnabled, lendingApy: nil) == nil)
    }

    @Test("A staking error drops the cached staking rate, as the Earn banner does, and shows the lending rate")
    func stakingErrorShowsLendingRate() throws {
        let cached = CachedStakingManagerState(rewardType: .apy, apy: Decimal(31) / 1000, stakeState: .availableToStake, date: Date())

        let info = try rewards(LeadingBadgeMapper.mapRewards(stakingManagerState: .loadingError("error", cached: cached), lendingApy: Decimal(24) / 1000))

        #expect(info.rewardValue == formatted(Decimal(24) / 1000))
        #expect(!info.isActive)
    }

    @Test("A stake cached while staking is off for maintenance gets no inactive lending badge, the row stays as it was before Lending")
    func cachedStakeWhileStakingIsOff() {
        let cached = CachedStakingManagerState(rewardType: .apy, apy: Decimal(31) / 1000, stakeState: .staked(balance: 1), date: Date())
        let staking = StakingManagerState.temporaryUnavailable(makeStakingYieldInfo(apy: Decimal(31) / 1000), cached: cached)

        #expect(LeadingBadgeMapper.mapRewards(stakingManagerState: staking, lendingApy: Decimal(24) / 1000) == nil)
    }

    @Test("While staking loads for the first time the badge waits for it instead of showing the lending rate")
    func firstStakingLoadWaits() {
        #expect(LeadingBadgeMapper.mapRewards(stakingManagerState: .loading(cached: nil), lendingApy: Decimal(24) / 1000) == nil)
    }

    @Test("While staking reloads the badge keeps the higher of the cached staking rate and the lending rate")
    func stakingReloadKeepsBestRate() throws {
        let cached = CachedStakingManagerState(rewardType: .apy, apy: Decimal(31) / 1000, stakeState: .availableToStake, date: Date())

        let info = try rewards(LeadingBadgeMapper.mapRewards(stakingManagerState: .loading(cached: cached), lendingApy: Decimal(24) / 1000))

        #expect(info.rewardValue == formatted(Decimal(31) / 1000))
        #expect(info.isUpdating)
    }

    @Test("A zero lending rate is left out of the badge")
    func zeroLendingRate() {
        #expect(LeadingBadgeMapper.mapRewards(stakingManagerState: .notEnabled, lendingApy: 0) == nil)
    }
}

// MARK: - Helpers

private extension LeadingBadgeMapperTests {
    struct NoRewardsBadge: Error {}

    func rewards(_ badge: TokenItemViewModel.LeadingBadge?) throws -> TokenItemViewModel.RewardsInfo {
        guard case .rewards(let info) = badge else {
            throw NoRewardsBadge()
        }

        return info
    }

    func formatted(_ apy: Decimal) -> String {
        PercentFormatter().format(apy, option: .yield)
    }

    func makeAvailableStaking(apy: Decimal, rewardType: RewardType = .apy) -> StakingManagerState {
        .availableToStake(makeStakingYieldInfo(apy: apy, rewardType: rewardType))
    }

    func makeStakingYieldInfo(apy: Decimal, rewardType: RewardType = .apy) -> StakingYieldInfo {
        StakingYieldInfo(
            id: "test",
            isAvailable: true,
            rewardType: rewardType,
            rewardRateValues: .single(apy),
            enterMinimumRequirement: 0,
            exitMinimumRequirement: 0,
            targets: [],
            preferredTargets: [],
            item: StakingTokenItem(network: .ethereum, contractAddress: nil, name: "", decimals: 0, symbol: ""),
            unbondingPeriod: .days(0),
            warmupPeriod: .days(0),
            rewardClaimingType: .manual,
            rewardScheduleType: .daily,
            rewardsIncludedInStake: false,
            maximumStakeAmount: nil
        )
    }
}
