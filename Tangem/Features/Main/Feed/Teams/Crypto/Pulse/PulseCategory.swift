//
//  PulseCategory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemLocalization

enum PulseCategory: CaseIterable, Hashable {
    case marketCap
    case topGainers
    case topLosers
    case experiencedBuyers
    case trending

    /// The only orders the list endpoint accepts together with `geckoCategoryId`.
    static let supportedWithTag: [PulseCategory] = [.marketCap, .topGainers, .topLosers]

    var title: String {
        switch self {
        case .marketCap: Localization.marketsSortByRatingTitle
        case .topGainers: Localization.marketsSortByTopGainersTitle
        case .topLosers: Localization.marketsSortByTopLosersTitle
        case .experiencedBuyers: Localization.marketsSortByExperiencedBuyersTitle
        case .trending: Localization.marketsSortByTrendingTitle
        }
    }
}
