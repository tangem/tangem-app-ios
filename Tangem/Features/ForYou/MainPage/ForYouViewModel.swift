//
//  ForYouViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

final class ForYouViewModel: ObservableObject {
    let portfolioReviewViewModel: PortfolioReviewViewModel
    let earnOpportunitiesViewModel: EarnOpportunitiesViewModel

    init(coordinator: ForYouRoutable? = nil) {
        portfolioReviewViewModel = .init(router: coordinator)
        earnOpportunitiesViewModel = .init(router: coordinator)
    }
}
