//
//  EarnFeedViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation

final class EarnFeedViewModel: ObservableObject {
    @Published private(set) var earnViewModel: EarnDetailViewModel?

    @Injected(\.earnDataFilterProvider) private var filterProvider: EarnDataFilterProvider
    @Injected(\.earnAnalyticsProvider) private var analyticsProvider: EarnAnalyticsProvider

    let promoBanner: PromotionNotificationsViewModel

    private var dataProvider: EarnDataProvider?

    private let router: any EarnFeedRoutable

    init(promotionNotificationsManager: PromotionNotificationsManager, router: any EarnFeedRoutable) {
        promoBanner = PromotionNotificationsViewModel(promotionNotificationsManager: promotionNotificationsManager)
        self.router = router
    }

    deinit {
        AppLogger.debug("EarnFeedViewModel deinit")
    }

    func onViewAppear() {
        Task { @MainActor [weak self] in
            guard let self else {
                return
            }

            // `EarnDetailViewModel` requests the list right from its initializer, and the data service drags the
            // whole staking graph in behind its P2P filter, so a tab nobody has opened builds neither.
            if earnViewModel == nil {
                let dataProvider = CommonEarnDataService(ethereumP2PFilter: CommonEarnEthereumP2PFilter())
                self.dataProvider = dataProvider

                earnViewModel = EarnDetailViewModel(
                    dataProvider: dataProvider,
                    filterProvider: filterProvider,
                    coordinator: self,
                    analyticsProvider: analyticsProvider
                )
            }

            // Every other host refreshes the carousel and logs the event per screen opening, so the tab does it
            // per appearance instead of once for the whole session.
            dataProvider?.refreshMostlyUsedTokens()
            analyticsProvider.logPageOpened()
        }
    }
}

// MARK: - EarnDetailRoutable

@MainActor
extension EarnFeedViewModel: EarnDetailRoutable {
    /// The tab has no navigation bar of its own, so nothing can ask the Earn content to close.
    func dismiss() {}

    func routeOnTokenResolved(_ resolution: EarnTokenResolution, source: EarnOpportunitySource) {
        router.routeOnTokenResolved(resolution, source: source)
    }

    func openNetworksFilter() {
        router.openNetworksFilter()
    }

    func openTypesFilter() {
        router.openTypesFilter()
    }
}
