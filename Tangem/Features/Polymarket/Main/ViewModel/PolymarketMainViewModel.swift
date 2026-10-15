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
    private weak var coordinator: PolymarketMainRoutable?

    private var bag: Set<AnyCancellable> = []

    init(
        balanceViewModel: PolymarketBalanceBlockViewModel,
        positionsViewModel: PolymarketPositionsBlockViewModel,
        searchViewModel: PolymarketSearchBlockViewModel,
        eventsViewModel: PolymarketEventsBlockViewModel,
        geoblockStateProvider: PolymarketGeoblockStateProvider,
        fundsArrivalTracker: PolymarketFundsArrivalTracker,
        withdrawTracker: PolymarketWithdrawTracker,
        refreshCenter: PolymarketMainRefreshCenter,
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
        self.coordinator = coordinator

        bindGeoblockState()
        bindFundsArrival()
        bindWithdrawal()
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
        }
    }

    enum ViewAction {
        case close
        case openHowItWorks
        case openSupportChat
        case openHistory
        case onTabsMove(minY: CGFloat, navBarHeight: CGFloat)
    }
}

// MARK: - Refresh

extension PolymarketMainViewModel {
    @MainActor
    func refresh() async {
        geoblockStateProvider.refresh()

        await refreshCenter.refresh(.full)
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

    func updatePinnedState(tabsMinY: CGFloat, navBarHeight: CGFloat) {
        let pinned = tabsMinY <= navBarHeight
        if pinned != isTabsPinned {
            isTabsPinned = pinned
        }
    }
}
