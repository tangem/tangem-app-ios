//
//  Period.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public enum Period: Hashable {
    case days(Int)
    case seconds(Int)
    case variable(minDays: Int, maxDays: Int)

    public var isZero: Bool {
        switch self {
        case .days(let days):
            return days == 0
        case .seconds(let seconds):
            return seconds == 0
        case .variable(let minDays, let maxDays):
            return minDays == 0 && maxDays == 0
        }
    }
}
