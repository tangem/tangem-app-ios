//
//  ForYouViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

final class ForYouViewModel: ObservableObject {
    let portfolioReview: PortfolioReviewViewModel
    let earnOpportunities: EarnOpportunitiesViewModel

    init(onExploreAllEarn: @MainActor @escaping () -> Void = {}) {
        portfolioReview = .init()
        earnOpportunities = .init(onExploreAllTokens: onExploreAllEarn)
    }
}
