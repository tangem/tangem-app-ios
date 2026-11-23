//
//  OnrampSummaryInteractorSuggestedOffers.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemExpress
import TangemMacro

typealias OnrampSummaryInteractorSuggestedOffers = [OnrampSummaryInteractorSuggestedOfferItem]

extension OnrampSummaryInteractorSuggestedOffers {
    var recent: OnrampProvider? {
        first(where: { $0.isRecent })?.provider
    }

    var recommended: [OnrampSummaryInteractorSuggestedOfferItem] {
        filter { !$0.isRecent }
    }
}

struct OnrampSummarySuggestedOffers {
    let recent: OnrampProvider?
    let recommended: [OnrampSummaryRecommendedEntry]
    let hasMoreOffers: Bool
}

@CaseFlagable
enum OnrampSummaryRecommendedEntry {
    case offer(OnrampSummaryInteractorSuggestedOfferItem)
    case replacedSlot(MarketingBanner.RecommendedSlot)
}

@CaseFlagable
enum OnrampSummaryInteractorSuggestedOfferItem {
    case recent(OnrampProvider)
    case nativeApplePay(OnrampProvider)
    case great(OnrampProvider)
    case fastest(OnrampProvider)
    case plain(OnrampProvider)

    var provider: OnrampProvider {
        switch self {
        case .recent(let provider): provider
        case .nativeApplePay(let provider): provider
        case .great(let provider): provider
        case .fastest(let provider): provider
        case .plain(let provider): provider
        }
    }

    var displayedSlot: MarketingBanner.RecommendedSlot? {
        guard !provider.isRestricted else {
            return nil
        }

        switch self {
        case .great:
            return .greatRate
        case .fastest:
            return .fastest
        case .nativeApplePay(let provider):
            switch provider.globalAttractiveType {
            case .best, .great: return .greatRate
            case .loss, .none: return .fastest
            }
        case .recent, .plain:
            return nil
        }
    }
}
