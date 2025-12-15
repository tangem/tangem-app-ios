//
//  Period.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public enum Period: Hashable {
    case specific(days: Int)
    case interval(minDays: Int, maxDays: Int)

    public var isZero: Bool {
        switch self {
        case .specific(let days):
            return days == 0
        case .interval(let minDays, let maxDays):
            return minDays == 0 && maxDays == 0
        }
    }
}
