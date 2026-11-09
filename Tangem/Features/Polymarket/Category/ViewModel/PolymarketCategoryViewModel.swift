//
//  PolymarketCategoryViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation
import TangemPolymarket

@MainActor
final class PolymarketCategoryViewModel: ObservableObject {
    @Published private(set) var fastTradingBanner: PolymarketFastTradingBanner?

    let title: String
    let eventsViewModel: PolymarketEventsBlockViewModel

    private let refreshCenter: PolymarketMainRefreshCenter
    private let fastTradingService: PolymarketFastTradingServicing?
    private weak var coordinator: PolymarketCategoryRoutable?

    private var fastTradingSubscription: AnyCancellable?

    init(
        category: PolymarketCategory,
        eventsViewModel: PolymarketEventsBlockViewModel,
        refreshCenter: PolymarketMainRefreshCenter,
        fastTradingService: PolymarketFastTradingServicing?,
        coordinator: PolymarketCategoryRoutable?
    ) {
        title = category.label
        self.eventsViewModel = eventsViewModel
        self.refreshCenter = refreshCenter
        self.fastTradingService = fastTradingService
        self.coordinator = coordinator

        bindFastTrading()
    }
}

// MARK: - View actions

extension PolymarketCategoryViewModel {
    func handleViewAction(_ action: ViewAction) {
        switch action {
        case .close:
            coordinator?.closeCategory()
        case .performFastTradingBannerAction:
            performFastTradingBannerAction()
        case .dismissFastTradingBanner:
            dismissFastTradingBanner()
        }
    }

    enum ViewAction {
        case close
        case performFastTradingBannerAction
        case dismissFastTradingBanner
    }
}

// MARK: - Fast trading

private extension PolymarketCategoryViewModel {
    func bindFastTrading() {
        fastTradingSubscription = fastTradingService?
            .bannerPublisher(includingForeignSigners: false)
            .receiveOnMain()
            .sink { [weak self] banner in
                self?.fastTradingBanner = banner
            }
    }

    func performFastTradingBannerAction() {
        guard let fastTradingBanner else { return }

        coordinator?.open(fastTradingBanner)
    }

    func dismissFastTradingBanner() {
        guard let fastTradingService, let fastTradingBanner else { return }

        fastTradingService.dismissBanner(fastTradingBanner)
    }
}

// MARK: - Refresh

extension PolymarketCategoryViewModel {
    func refresh() async {
        await refreshCenter.refresh(.full)
    }
}
