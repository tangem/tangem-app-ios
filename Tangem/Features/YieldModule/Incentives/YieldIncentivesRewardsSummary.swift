//
//  YieldIncentivesRewardsSummary.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct YieldIncentivesRewardsSummary: Equatable {
    let moduleAddress: String
    let rewards: [YieldIncentiveReward]
    let lastUpdatedAt: Date

    var claimableRewards: [YieldIncentiveReward] {
        rewards.filter(\.isClaimable)
    }

    var pendingRewards: [YieldIncentiveReward] {
        rewards.filter(\.hasPending)
    }

    var totalClaimableNetUsd: Decimal {
        claimableRewards.reduce(0) { $0 + $1.estimatedNetValueUsd }
    }

    var isClaimRecommended: Bool {
        claimableRewards.contains(where: \.claimRecommended)
    }
}

extension YieldIncentivesRewardsSummary {
    init?(dto: YieldModuleDTO.Response.IncentivesInfo) {
        guard let moduleAddress = dto.moduleAddress, !dto.rewards.isEmpty else {
            return nil
        }

        self.init(
            moduleAddress: moduleAddress,
            rewards: dto.rewards.map(YieldIncentiveReward.init(dto:)),
            lastUpdatedAt: dto.lastUpdatedAt
        )
    }
}
