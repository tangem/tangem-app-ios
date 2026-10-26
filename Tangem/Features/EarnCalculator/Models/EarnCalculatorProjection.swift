//
//  EarnCalculatorProjection.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct EarnCalculatorInput: Hashable {
    var initialBalance: Decimal
    var monthlyTopUp: Decimal
    var horizon: EarnCalculatorHorizon

    subscript(field: EarnCalculatorField) -> Decimal {
        get {
            switch field {
            case .initialBalance: initialBalance
            case .monthlyTopUp: monthlyTopUp
            }
        }
        set {
            switch field {
            case .initialBalance: initialBalance = newValue
            case .monthlyTopUp: monthlyTopUp = newValue
            }
        }
    }
}

extension EarnCalculatorInput {
    static let `default` = EarnCalculatorInput(initialBalance: 2500, monthlyTopUp: 500, horizon: .threeYears)
}

struct EarnCalculatorProjection: Hashable {
    let points: [Point]

    var finalBalance: Decimal { points.last?.balance ?? .zero }
    var earned: Decimal { points.last?.earned ?? .zero }
}

extension EarnCalculatorProjection {
    struct Point: Hashable {
        let month: Int
        let balance: Decimal
        let earned: Decimal
    }
}
