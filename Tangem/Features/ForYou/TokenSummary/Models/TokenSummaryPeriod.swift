//
//  TokenSummaryPeriod.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemLocalization
import TangemUI

enum TokenSummaryPeriod: CaseIterable, Identifiable {
    case day
    case week
    case month

    var id: Self { self }

    /// The shared period keys spell lowercase units ("day"), while the picker shows them as labels.
    var title: String {
        let unit = switch self {
        case .day: Localization.commonDay
        case .week: Localization.commonWeek
        case .month: Localization.commonMonth
        }

        return unit.capitalizingFirstLetter()
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
