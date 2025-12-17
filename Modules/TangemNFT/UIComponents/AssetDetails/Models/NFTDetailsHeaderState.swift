//
//  NFTDetailsHeaderState.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemUI
import TangemFoundation

enum NFTDetailsHeaderState {
    case full(PriceWithDescriptionState, [KeyValuePairViewData])
    case priceWithDescription(PriceWithDescriptionState)
    case rarity([KeyValuePairViewData])
}

extension NFTDetailsHeaderState {
    enum PriceWithDescriptionState {
        case price(Price)
        case description(DescriptionConfig)
        case priceWithDescription(Price, DescriptionConfig)
    }

    struct Price {
        let crypto: String
        let fiat: LoadingResult<String, any Error>
    }

    struct DescriptionConfig {
        let text: String
        let readMoreAction: @MainActor () -> Void
    }
}
