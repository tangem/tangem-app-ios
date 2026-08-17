//
//  TokenSummaryPeriod.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemUI

enum TokenSummaryPeriod: CaseIterable, Identifiable {
    case day
    case week
    case month

    var id: Self { self }

    // [REDACTED_TODO_COMMENT]
    var title: String {
        switch self {
        case .day: "Day"
        case .week: "Week"
        case .month: "Month"
        }
    }
}

extension TokenSummaryPeriod {
    var timeframe: TokenSummaryIndicator.Timeframe {
        switch self {
        case .day: .day
        case .week: .week
        case .month: .month
        }
    }
}

// MARK: - TangemSegmentedPickerTextProvider

extension TokenSummaryPeriod: TangemSegmentedPickerTextProvider {
    var text: String { title }
}
