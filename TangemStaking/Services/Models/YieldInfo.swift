//
//  StakingInfo.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

public struct YieldInfo {
    let contractAddress: String?
    let apy: Decimal
    let rewardRate: Decimal
    let rewardType: RewardType
    let unbonding: Period
    let minimumRequirement: Decimal
    let rewardClaimingType: RewardClaimingType
    let warmupPeriod: Period
    let rewardScheduleType: RewardScheduleType
}

public enum Period {
    case days(_ days: Int)

    // [REDACTED_TODO_COMMENT]
    func formatted(formatter: DateComponentsFormatter) -> String {
        switch self {
        case .days(let days):
            formatter.unitsStyle = .short
            formatter.allowedUnits = [.day]
            return formatter.string(from: DateComponents(day: days)) ?? days.formatted()
        }
    }
}

public enum RewardClaimingType: String, Hashable {
    case auto
    case manual
}

public enum RewardScheduleType: String, Hashable {
    case block
}

public enum RewardType: String, Hashable {
    case apr
    case apy
    case variable
}
