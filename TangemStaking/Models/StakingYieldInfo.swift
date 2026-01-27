//
//  StakingInfo.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public struct StakingYieldInfo: Hashable {
    public let id: String
    public let isAvailable: Bool

    // Rewards
    public let rewardType: RewardType
    public let rewardRateValues: RewardRateValues

    // Actions
    public let enterMinimumRequirement: Decimal
    public let exitMinimumRequirement: Decimal

    // Validators
    public let targets: [StakingTargetInfo]
    public let preferredTargets: [StakingTargetInfo]

    // Metadata
    public let item: StakingTokenItem
    public let unbondingPeriod: Period
    public let warmupPeriod: Period

    public let rewardClaimingType: RewardClaimingType
    public let rewardScheduleType: RewardScheduleType

    public let maximumStakeAmount: Decimal?

    public init(
        id: String,
        isAvailable: Bool,
        rewardType: RewardType,
        rewardRateValues: RewardRateValues,
        enterMinimumRequirement: Decimal,
        exitMinimumRequirement: Decimal,
        targets: [StakingTargetInfo],
        preferredTargets: [StakingTargetInfo],
        item: StakingTokenItem,
        unbondingPeriod: Period,
        warmupPeriod: Period,
        rewardClaimingType: RewardClaimingType,
        rewardScheduleType: RewardScheduleType,
        maximumStakeAmount: Decimal?
    ) {
        self.id = id
        self.isAvailable = isAvailable
        self.rewardType = rewardType
        self.rewardRateValues = rewardRateValues
        self.enterMinimumRequirement = enterMinimumRequirement
        self.exitMinimumRequirement = exitMinimumRequirement
        self.targets = targets
        self.preferredTargets = preferredTargets
        self.item = item
        self.unbondingPeriod = unbondingPeriod
        self.warmupPeriod = warmupPeriod
        self.rewardClaimingType = rewardClaimingType
        self.rewardScheduleType = rewardScheduleType
        self.maximumStakeAmount = maximumStakeAmount
    }
}
