//
//  StubEarnCalculatorProjector.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct StubEarnCalculatorProjector: EarnCalculatorProjecting {
    var monthlyRate: Decimal = 0.004

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
