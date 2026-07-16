//
//  PortfolioReviewViewModel+State.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension PortfolioReviewViewModel {
    /// View-state model for the For You Portfolio Review screen. There is no screen-level loading
    /// case: the token list renders as soon as the wallet structure is known, and each row shimmers
    /// its own value while the balance loads.
    struct ViewState: Equatable {
        let tokenList: [ForYouTokenListItem]
        let periodSegments: [ForYouPeriodSegment]
    }
}
