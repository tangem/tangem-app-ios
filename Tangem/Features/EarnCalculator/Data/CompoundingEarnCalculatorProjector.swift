//
//  CompoundingEarnCalculatorProjector.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct CompoundingEarnCalculatorProjector: EarnCalculatorProjecting {
    private let monthlyRate: Decimal

    init(apy: Decimal, performanceFee: Decimal) {
        let netApy = apy * (1 - performanceFee)
        monthlyRate = Decimal(pow(1 + netApy.doubleValue, 1.0 / 12) - 1)
    }

    func project(_ input: EarnCalculatorInput) -> EarnCalculatorProjection {
        var balance = input.initialBalance
        var contributed = input.initialBalance

        let points = (1 ... input.horizon.months).map { month in
            balance = balance * (1 + monthlyRate) + input.monthlyTopUp
            contributed += input.monthlyTopUp

            return EarnCalculatorProjection.Point(month: month, balance: balance, earned: balance - contributed)
        }

        return EarnCalculatorProjection(points: points)
    }
}

extension CompoundingEarnCalculatorProjector {
    static let preview = CompoundingEarnCalculatorProjector(apy: 0.055, performanceFee: 0.15)
}
