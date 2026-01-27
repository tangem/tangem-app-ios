//
//  MarketsWidgetType.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

enum MarketsWidgetType: String, Identifiable, CaseIterable {
    case market
    case news
    case earn
    case pulse

    var id: String {
        rawValue
    }

    var headerTitle: String? {
        switch self {
        case .market:
            return Localization.marketsCommonTitle
        case .news:
            return Localization.commonNews
        case .earn:
            return Localization.marketsEarnCommonTitle
        case .pulse:
            return Localization.marketsPulseCommonTitle
        }
    }
}
