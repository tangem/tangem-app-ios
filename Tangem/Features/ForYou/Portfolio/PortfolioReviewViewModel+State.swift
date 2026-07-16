//
//  PortfolioReviewViewModel+State.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension PortfolioReviewViewModel {
    /// View-state model for the For You Portfolio Review screen.
    enum ViewState: Equatable {
        case loading
        case content(Content)

        struct Content: Equatable {
            let tokenList: [ForYouTokenListItem]
            let periodSegments: [ForYouPeriodSegment]
        }
    }
}
