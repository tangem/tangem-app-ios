//
//  MarketsListOrderType.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

enum MarketsListOrderType: String, CaseIterable, Encodable, CustomStringConvertible, Identifiable {
    case rating
    case trending
    case buyers
    case gainers
    case losers
    case staking
    case yield

    var id: String {
        rawValue
    }

    var analyticsValue: String {
        switch self {
        case .yield: "yield mode"
        default: rawValue
        }
    }

    var description: String {
        switch self {
        case .rating: return Localization.marketsSortByRatingTitle
        case .trending: return Localization.marketsSortByTrendingTitle
        case .buyers: return Localization.marketsSortByExperiencedBuyersTitle
        case .gainers: return Localization.marketsSortByTopGainersTitle
        case .losers: return Localization.marketsSortByTopLosersTitle
        case .staking: return Localization.commonStaking
        case .yield: return Localization.commonYieldMode
        }
    }
}
