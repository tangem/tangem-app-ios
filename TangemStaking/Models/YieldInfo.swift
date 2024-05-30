//
//  StakingInfo.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public struct YieldInfo {
    public let id: String
    public let item: StakingTokenItem
    public let apy: Decimal
    public let rewardRate: Decimal
    public let rewardType: RewardType
    public let unbonding: Period
    public let minimumRequirement: Decimal
    public let rewardClaimingType: RewardClaimingType
    public let warmupPeriod: Period
    public let rewardScheduleType: RewardScheduleType

    public init(
        id: String,
        item: StakingTokenItem,
        apy: Decimal,
        rewardRate: Decimal,
        rewardType: RewardType,
        unbonding: Period,
        minimumRequirement: Decimal,
        rewardClaimingType: RewardClaimingType,
        warmupPeriod: Period,
        rewardScheduleType: RewardScheduleType
    ) {
        self.id = id
        self.item = item
        self.apy = apy
        self.rewardRate = rewardRate
        self.rewardType = rewardType
        self.unbonding = unbonding
        self.minimumRequirement = minimumRequirement
        self.rewardClaimingType = rewardClaimingType
        self.warmupPeriod = warmupPeriod
        self.rewardScheduleType = rewardScheduleType
    }
}
