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
    private let fastTradingService: PolymarketFastTradingServicing?
    private weak var coordinator: PolymarketMainRoutable?

    private var bag: Set<AnyCancellable> = []
    private var fastTradingSubscription: AnyCancellable?

    init(
        balanceViewModel: PolymarketBalanceBlockViewModel,
        positionsViewModel: PolymarketPositionsBlockViewModel,
        searchViewModel: PolymarketSearchBlockViewModel,
        eventsViewModel: PolymarketEventsBlockViewModel,
        geoblockStateProvider: PolymarketGeoblockStateProvider,
        fundsArrivalTracker: PolymarketFundsArrivalTracker,
        withdrawTracker: PolymarketWithdrawTracker,
        refreshCenter: PolymarketMainRefreshCenter,
        fastTradingService: PolymarketFastTradingServicing?,
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
        self.fastTradingService = fastTradingService
        self.coordinator = coordinator

        bindGeoblockState()
        bindFundsArrival()
        bindWithdrawal()
        bindSearch()
    }
}

// MARK: - Fast trading

extension PolymarketMainViewModel {
    var isFastTradingAvailable: Bool {
        fastTradingService != nil
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
        case .onAppear:
            bindFastTrading()
        case .openSettings:
            coordinator?.openSettings()
        case .performFastTradingBannerAction:
            performFastTradingBannerAction()
        case .dismissFastTradingBanner:
            dismissFastTradingBanner()
        }
    }

    enum ViewAction {
        case close
        case openHowItWorks
        case openSupportChat
        case openHistory
        case onTabsMove(minY: CGFloat, navBarHeight: CGFloat)
        case onAppear
        case openSettings
        case performFastTradingBannerAction
        case dismissFastTradingBanner
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
        guard let fastTradingService, fastTradingSubscription == nil else {
            return
        }

        fastTradingSubscription = fastTradingService
            .bannerPublisher(includingForeignSigners: true)
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, banner in
                viewModel.fastTradingBanner = banner
            }

        Task { await fastTradingService.refresh() }
    }

    @MainActor
    func refreshFastTrading() async {
        await fastTradingService?.refresh()
    }

    @MainActor
    func performFastTradingBannerAction() {
        guard let fastTradingBanner else { return }

        coordinator?.open(fastTradingBanner)
    }

    @MainActor
    func dismissFastTradingBanner() {
        guard let fastTradingService, let fastTradingBanner else {
            return
        }

        fastTradingService.dismissBanner(fastTradingBanner)
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
