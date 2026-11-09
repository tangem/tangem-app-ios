//
//  EarnCalculatorViewState.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct EarnCalculatorViewState: Equatable {
    let incentiveBadgeText: String?
    let totalBalance: String
    let earned: String
    let horizonTitle: String
    let bars: [Bar]
    let inputs: [Input]
}

extension EarnCalculatorViewState {
    struct Bar: Identifiable, Equatable {
        let id: Int
        let month: Int
        let axisLabel: String?
        let normalizedHeight: Double
        let balance: String
        let earned: String
    }

    struct Input: Identifiable, Equatable {
        let field: EarnCalculatorField
        let title: String
        let currencySymbol: String
        let value: String
        let canDecrease: Bool
        let canIncrease: Bool

        var id: EarnCalculatorField { field }
    }
}
