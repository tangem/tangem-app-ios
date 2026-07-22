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

    private weak var coordinator: ForYouRoutable?

    init(
        coordinator: ForYouRoutable? = nil,
        onExploreAllEarn: @MainActor @escaping () -> Void = {},
        onAddFunds: @MainActor @escaping () -> Void = {}
    ) {
        self.coordinator = coordinator
        portfolioReview = .init(onAddFunds: onAddFunds)
        earnOpportunities = .init(onExploreAllTokens: onExploreAllEarn)
        portfolioReview.onSelectToken = { [weak self] tokenItem in
            self?.coordinator?.openTokenSummary(tokenItem: tokenItem)
        }
    }
}
