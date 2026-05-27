//
//  MarketsListOrderType.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import TangemMacro
import TangemUI

@CaseFlagable
enum MarketsListOrderType: String, CaseIterable, Encodable, CustomStringConvertible, Identifiable {
    case rating
    case trending
    case buyers
    case gainers
    case losers

    var id: String {
        rawValue
    }

    var analyticsValue: String {
        rawValue
    }

    var description: String {
        switch self {
        case .rating: return Localization.marketsSortByRatingTitle
        case .trending: return Localization.marketsSortByTrendingTitle
        case .buyers: return Localization.marketsSortByExperiencedBuyersTitle
        case .gainers: return Localization.marketsSortByTopGainersTitle
        case .losers: return Localization.marketsSortByTopLosersTitle
        }
    }
}

// MARK: - TangemDropDownTextProvider

extension MarketsListOrderType: TangemDropDownTextProvider {
    public var text: String {
        description
    }
}
