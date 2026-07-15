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
    // [REDACTED_TODO_COMMENT]
    @Published private(set) var walletTabs: [ForYouWalletTab]
    @Published private(set) var portfolioReview: PortfolioReviewState
    @Published private(set) var notifications: [NotificationViewInput] = []
    @Published var selectedPeriod = ForYouPeriodSegment.initial

    let tokenListViewModel: PortfolioTokenListViewModel

    private let dataSource: ForYouPortfolioDataSource
    private var bag: Set<AnyCancellable> = []

    // [REDACTED_TODO_COMMENT]
    private static let placeholderWalletTabs: [ForYouWalletTab] = [
        ForYouWalletTab(id: "w1", name: "Main Wallet", isSelected: true, count: nil),
        ForYouWalletTab(id: "w2", name: "Wallet 2", isSelected: false, count: nil),
    ]

    init(dataSource: ForYouPortfolioDataSource) {
        let initialState = PortfolioReviewState.loadingPlaceholder

        self.dataSource = dataSource
        walletTabs = Self.placeholderWalletTabs
        portfolioReview = initialState
        tokenListViewModel = PortfolioTokenListViewModel(items: initialState.tokenList)

        bind()
    }

    /// Fixed-state seed, no subscription — for previews.
    init(previewState: PortfolioReviewState) {
        dataSource = MockForYouPortfolioDataSource(state: previewState)
        walletTabs = Self.placeholderWalletTabs
        portfolioReview = previewState
        tokenListViewModel = PortfolioTokenListViewModel(items: previewState.tokenList)
    }

    // MARK: - View events

    func onWalletTabTap(id: String) {
        walletTabs = walletTabs.map { tab in
            ForYouWalletTab(id: tab.id, name: tab.name, isSelected: tab.id == id, count: tab.count)
        }
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

        dataSource.notificationsPublisher
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { viewModel, notifications in
                viewModel.notifications = notifications
            }
            .store(in: &bag)
    }
}
