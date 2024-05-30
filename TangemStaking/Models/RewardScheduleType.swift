//
//  RewardScheduleType.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public enum RewardScheduleType: String, Hashable {
    case block
    case hour
    case day
    case week
    case month
    case era
    case epoch
}
