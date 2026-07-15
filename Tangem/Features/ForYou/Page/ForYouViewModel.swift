//
//  ForYouViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

final class ForYouViewModel: ObservableObject {
    let portfolioReview: PortfolioReviewViewModel

    init() {
        portfolioReview = PortfolioReviewViewModel()
    }
}
