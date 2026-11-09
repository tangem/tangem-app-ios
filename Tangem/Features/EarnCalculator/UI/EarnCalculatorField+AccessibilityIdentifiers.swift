//
//  EarnCalculatorField+AccessibilityIdentifiers.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemAccessibilityIdentifiers

extension EarnCalculatorField {
    var decreaseButtonIdentifier: String {
        switch self {
        case .initialBalance: EarnCalculatorAccessibilityIdentifiers.initialBalanceDecreaseButton
        case .monthlyTopUp: EarnCalculatorAccessibilityIdentifiers.monthlyTopUpDecreaseButton
        }
    }

    var increaseButtonIdentifier: String {
        switch self {
        case .initialBalance: EarnCalculatorAccessibilityIdentifiers.initialBalanceIncreaseButton
        case .monthlyTopUp: EarnCalculatorAccessibilityIdentifiers.monthlyTopUpIncreaseButton
        }
    }
}
