//
//  PulseInterval.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemLocalization

enum PulseInterval: CaseIterable, Hashable {
    case day
    case week
    case month

    var title: String {
        switch self {
        case .day: Localization.marketsSelectorInterval24hTitle
        case .week: Localization.marketsSelectorInterval7dTitle
        case .month: Localization.marketsSelectorInterval1mTitle
        }
    }
}
