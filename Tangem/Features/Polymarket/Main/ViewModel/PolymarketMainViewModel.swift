//
//  PolymarketMainViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine
import TangemFoundation
import TangemPolymarket
import TangemPolymarketUI

final class PolymarketMainViewModel: ObservableObject {
    @Published private(set) var isTabsPinned = false
    @Published private(set) var isRegionRestricted = false
    @Published private(set) var isAwaitingFunds = false
    @Published private(set) var scrollToTopRequest = 0
    @Published private(set) var withdrawalState: PolymarketWithdrawState?
    @Published private(set) var fastTradingBanner: PolymarketFastTradingBanner?

    var fundingNotifications: [PolymarketOrderNotification] {
        [
            isAwaitingFunds ? .awaitingFunds : nil,
            withdrawalState.map(PolymarketOrderNotification.init(withdrawState:)),
        ]
        .compactMap { $0 }
    }

    let balanceViewModel: PolymarketBalanceBlockViewModel
    let positionsViewModel: PolymarketPositionsBlockViewModel
    let searchViewModel: PolymarketSearchBlockViewModel
    let eventsViewModel: PolymarketEventsBlockViewModel

    private let geoblockStateProvider: PolymarketGeoblockStateProvider
    private let fundsArrivalTracker: PolymarketFundsArrivalTracker
    private let withdrawTracker: PolymarketWithdrawTracker
    private let refreshCenter: PolymarketMainRefreshCenter
    private let fastTrading: PolymarketFastTradingBannerProviding?
    private weak var coordinator: PolymarketMainRoutable?

    private var bag: Set<AnyCancellable> = []
    private var fastTradingSubscription: AnyCancellable?

    @MainActor
    init(
        balanceViewModel: PolymarketBalanceBlockViewModel,
        positionsViewModel: PolymarketPositionsBlockViewModel,
        searchViewModel: PolymarketSearchBlockViewModel,
        eventsViewModel: PolymarketEventsBlockViewModel,
        geoblockStateProvider: PolymarketGeoblockStateProvider,
        fundsArrivalTracker: PolymarketFundsArrivalTracker,
        withdrawTracker: PolymarketWithdrawTracker,
        refreshCenter: PolymarketMainRefreshCenter,
        fastTrading: PolymarketFastTradingBannerProviding?,
        coordinator: PolymarketMainRoutable
    ) {
        self.balanceViewModel = balanceViewModel
        self.positionsViewModel = positionsViewModel
        self.searchViewModel = searchViewModel
        self.eventsViewModel = eventsViewModel
        self.geoblockStateProvider = geoblockStateProvider
        self.fundsArrivalTracker = fundsArrivalTracker
        self.withdrawTracker = withdrawTracker
        self.refreshCenter = refreshCenter
        self.fastTrading = fastTrading
        self.coordinator = coordinator

        bindGeoblockState()
        bindFundsArrival()
        bindWithdrawal()
        bindSearch()
        bindFastTrading()
    }
}

// MARK: - Fast trading

extension PolymarketMainViewModel {
    var isFastTradingAvailable: Bool {
        fastTrading != nil
    }
}

// MARK: - Scroll

extension PolymarketMainViewModel {
    func scrollToTop() {
        scrollToTopRequest += 1
    }
}

// MARK: - View actions

extension PolymarketMainViewModel {
    @MainActor
    func handleViewAction(_ action: ViewAction) {
        switch action {
        case .close:
            coordinator?.dismiss()
        case .openHowItWorks:
            coordinator?.openHowItWorks()
        case .openSupportChat:
            coordinator?.openSupportChat()
        case .openHistory:
            coordinator?.openActivity()
        case .onTabsMove(let minY, let navBarHeight):
            updatePinnedState(tabsMinY: minY, navBarHeight: navBarHeight)
        case .openSettings:
            coordinator?.openSettings()
        case .performFastTradingBannerAction(let banner):
            coordinator?.open(banner)
        case .dismissFastTradingBanner(let banner):
            fastTrading?.dismissBanner(banner)
        }
    }

    enum ViewAction {
        case close
        case openHowItWorks
        case openSupportChat
        case openHistory
        case onTabsMove(minY: CGFloat, navBarHeight: CGFloat)
        case openSettings
        case performFastTradingBannerAction(PolymarketFastTradingBanner)
        case dismissFastTradingBanner(PolymarketFastTradingBanner)
    }
}

// MARK: - Refresh

extension PolymarketMainViewModel {
    @MainActor
    func refresh() async {
        geoblockStateProvider.refresh()

        async let fastTradingRefresh: Void = refreshFastTrading()
        await refreshCenter.refresh(.full)
        await fastTradingRefresh
    }
}

// MARK: - Private implementation

private extension PolymarketMainViewModel {
    func bindFundsArrival() {
        fundsArrivalTracker
            .$isAwaitingFunds
            .receiveOnMain()
            .assign(to: &$isAwaitingFunds)
    }

    func bindWithdrawal() {
        withdrawalState = withdrawTracker.state

        withdrawTracker
            .statePublisher
            .receiveOnMain()
            .assign(to: &$withdrawalState)
    }

    func bindGeoblockState() {
        geoblockStateProvider
            .statePublisher
            .map(\.isBlocked)
            .removeDuplicates()
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, isRestricted in
                viewModel.isRegionRestricted = isRestricted

                if isRestricted {
                    viewModel.coordinator?.openRegionWarning()
                }
            }
            .store(in: &bag)
    }

    @MainActor
    func bindFastTrading() {
        guard let fastTrading else { return }

        fastTradingSubscription = PolymarketFastTradingBannerMapper(includesForeignSigners: true)
            .mapToBannerPublisher(states: fastTrading.statePublisher, dismissals: fastTrading.bannerDismissalsPublisher)
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, banner in
                viewModel.fastTradingBanner = banner
            }

        Task { await fastTrading.refresh() }
    }

    @MainActor
    func refreshFastTrading() async {
        await fastTrading?.refresh()
    }

    func bindSearch() {
        searchViewModel
            .$isSearching
            .removeDuplicates()
            .receiveOnMain()
            .withWeakCaptureOf(eventsViewModel)
            .sink { eventsViewModel, isSearching in
                MainActor.assumeIsolated {
                    eventsViewModel.setPollingSuspended(isSearching)
                }
            }
            .store(in: &bag)
    }

    func updatePinnedState(tabsMinY: CGFloat, navBarHeight: CGFloat) {
        let pinned = tabsMinY <= navBarHeight
        if pinned != isTabsPinned {
            isTabsPinned = pinned
        }
    }
}
