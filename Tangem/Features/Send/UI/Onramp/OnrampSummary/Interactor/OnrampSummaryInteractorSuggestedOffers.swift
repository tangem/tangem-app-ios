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

@CaseFlagable
enum OnrampSummaryInteractorSuggestedOfferItem {
    case recent(OnrampProvider)
    case great(OnrampProvider)
    case fastest(OnrampProvider)
    case plain(OnrampProvider)

    var provider: OnrampProvider {
        switch self {
        case .recent(let provider): provider
        case .great(let provider): provider
        case .fastest(let provider): provider
        case .plain(let provider): provider
        }
    }
}
