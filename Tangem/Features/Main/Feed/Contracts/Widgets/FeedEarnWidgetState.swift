//
//  FeedEarnWidgetState.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

struct FeedEarnWidgetState: Equatable {
    private static let percentFormatter = PercentFormatter()

    let maxAPY: Decimal
    let tokenSymbol: String?

    var caption: String {
        tokenSymbol == nil ? Localization.feedPromoEarnTitle : Localization.feedPromoEarnActiveTitle
    }

    var message: String {
        let rate = Self.percentFormatter.format(maxAPY, option: .yield)

        guard let tokenSymbol else {
            return Localization.feedPromoEarnDescription(rate)
        }

        return Localization.feedPromoEarnActiveDescription(rate, tokenSymbol)
    }
}
