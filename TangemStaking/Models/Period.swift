//
//  Period.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public enum Period: Hashable {
    case constant(days: Int)
    case variable(minDays: Int, maxDays: Int)

    public var isZero: Bool {
        switch self {
        case .constant(let days):
            return days == 0
        case .variable(let minDays, let maxDays):
            return minDays == 0 && maxDays == 0
        }
    }
}
