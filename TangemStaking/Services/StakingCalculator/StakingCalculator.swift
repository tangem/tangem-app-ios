//
//  StakingCalculator.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public struct StakingCalculator {
    public init() {}

    public func earnValue(invest: Decimal, apr: Decimal, period: Period) -> Decimal {
        switch period {
        case .days(let days):
            let daily = apr / 365
            let value = invest * daily * Decimal(days)
            return value
        }
    }
}
