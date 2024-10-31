//
//  RewardScheduleType.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public enum RewardScheduleType: Hashable {
    case generic(String)

    case seconds(min: Int, max: Int)
    case daily
    case days(min: Int, max: Int)
}
