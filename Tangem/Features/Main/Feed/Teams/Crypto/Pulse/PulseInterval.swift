//
//  PulseInterval.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemLocalization

/// The raw values are the accessibility identifiers the shtorka's other interval controls already carry, so they
/// spell chart ranges rather than the case names and a rename can't move them.
enum PulseInterval: String, CaseIterable, Hashable {
    case day = "24h"
    case week = "1w"
    case month = "1m"

    var title: String {
        switch self {
        case .day: Localization.marketsSelectorInterval24hTitle
        case .week: Localization.marketsRealAssetsIntervalWeek
        case .month: Localization.marketsRealAssetsIntervalMonth
        }
    }
}
