//
//  EarnCalculatorField.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum EarnCalculatorField: Hashable {
    case initialBalance
    case monthlyTopUp

    // [REDACTED_TODO_COMMENT]
    var step: Decimal {
        switch self {
        case .initialBalance: 100
        case .monthlyTopUp: 50
        }
    }

    var range: ClosedRange<Decimal> {
        switch self {
        case .initialBalance: 0 ... 1_000_000
        case .monthlyTopUp: 0 ... 100_000
        }
    }

    // [REDACTED_TODO_COMMENT]
    var title: String {
        switch self {
        case .initialBalance: "Initial balance"
        case .monthlyTopUp: "Monthly top-up"
        }
    }
}
