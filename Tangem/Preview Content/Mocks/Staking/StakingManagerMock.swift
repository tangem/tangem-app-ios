//
//  StakingManagerMock.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking

actor StakingManagerMock: StakingManager {
    func getYield(item: StakingTokenItem) async throws -> YieldInfo {
        YieldInfo(
            id: "ethereum-staking",
            item: .init(network: "ethereum", contractAdress: nil),
            apy: 3.54,
            rewardRate: 5.06,
            rewardType: .apr,
            unbonding: .days(3),
            minimumRequirement: 300,
            rewardClaimingType: .auto,
            warmupPeriod: .days(3),
            rewardScheduleType: .block
        )
    }
}
