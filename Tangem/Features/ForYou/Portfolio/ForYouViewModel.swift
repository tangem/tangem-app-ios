//
//  ForYouViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

final class ForYouViewModel: ObservableObject {
    @Published private(set) var portfolioReview: PortfolioReviewState
    @Published var selectedPeriod = ForYouPeriodSegment.initial

    let tokenListViewModel: PortfolioTokenListViewModel

    private let dataSource: ForYouPortfolioDataSource
    private var bag: Set<AnyCancellable> = []

    init(dataSource: ForYouPortfolioDataSource) {
        let initialState = PortfolioReviewState.loadingPlaceholder

        self.dataSource = dataSource
        portfolioReview = initialState
        tokenListViewModel = PortfolioTokenListViewModel(items: initialState.tokenList)

        bind()
    }
}

// MARK: - Bind

private extension ForYouViewModel {
    func bind() {
        dataSource.statePublisher
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { viewModel, state in
                viewModel.portfolioReview = state
                viewModel.tokenListViewModel.update(items: state.tokenList)
            }
            .store(in: &bag)
    }
}
