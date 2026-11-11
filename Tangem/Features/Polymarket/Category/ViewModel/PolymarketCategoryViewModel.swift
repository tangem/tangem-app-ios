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
    private let fastTrading: PolymarketFastTradingBannerProviding?
    private weak var coordinator: PolymarketCategoryRoutable?

    private var fastTradingSubscription: AnyCancellable?

    init(
        category: PolymarketCategory,
        eventsViewModel: PolymarketEventsBlockViewModel,
        refreshCenter: PolymarketMainRefreshCenter,
        fastTrading: PolymarketFastTradingBannerProviding?,
        coordinator: PolymarketCategoryRoutable?
    ) {
        title = category.label
        self.eventsViewModel = eventsViewModel
        self.refreshCenter = refreshCenter
        self.fastTrading = fastTrading
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
        case .performFastTradingBannerAction(let banner):
            coordinator?.open(banner)
        case .dismissFastTradingBanner(let banner):
            fastTrading?.dismissBanner(banner)
        }
    }

    enum ViewAction {
        case close
        case performFastTradingBannerAction(PolymarketFastTradingBanner)
        case dismissFastTradingBanner(PolymarketFastTradingBanner)
    }
}

// MARK: - Fast trading

private extension PolymarketCategoryViewModel {
    func bindFastTrading() {
        guard let fastTrading else { return }

        fastTradingSubscription = PolymarketFastTradingBannerMapper(includesForeignSigners: false)
            .mapToBannerPublisher(states: fastTrading.statePublisher, dismissals: fastTrading.bannerDismissalsPublisher)
            .receiveOnMain()
            .sink { [weak self] banner in
                self?.fastTradingBanner = banner
            }
    }
}

// MARK: - Refresh

extension PolymarketCategoryViewModel {
    func refresh() async {
        async let fastTradingRefresh: Void = refreshFastTrading()
        await refreshCenter.refresh(.full)
        await fastTradingRefresh
    }

    private func refreshFastTrading() async {
        await fastTrading?.refresh()
    }
}
