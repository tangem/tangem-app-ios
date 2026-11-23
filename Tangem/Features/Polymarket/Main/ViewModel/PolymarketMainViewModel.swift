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
    @Published private(set) var isContentRevealed = false
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
    private let revealDelayProvider: PollDelayProvider
    private weak var coordinator: PolymarketMainRoutable?

    private var bag: Set<AnyCancellable> = []
    private var fastTradingSubscription: AnyCancellable?
    private var revealTimeoutTask: Task<Void, Never>?

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
        revealDelayProvider: PollDelayProvider = TaskSleepPollDelayProvider(),
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
        self.revealDelayProvider = revealDelayProvider
        self.coordinator = coordinator
        isContentRevealed = fastTrading == nil

        bindGeoblockState()
        bindFundsArrival()
        bindWithdrawal()
        bindSearch()
        bindFastTrading()
        scheduleRevealTimeout()
    }

    deinit {
        revealTimeoutTask?.cancel()
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
        isAwaitingFunds = fundsArrivalTracker.isAwaitingFunds

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
            .removeDuplicates()
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, state in
                viewModel.apply(regionState: state)
            }
            .store(in: &bag)
    }

    func apply(regionState: PolymarketGeoblockState) {
        if regionState.isBlocked != isRegionRestricted {
            isRegionRestricted = regionState.isBlocked

            if regionState.isBlocked {
                coordinator?.openRegionWarning()
            }
        }
    }

    @MainActor
    func bindFastTrading() {
        guard let fastTrading else { return }

        let mapper = PolymarketFastTradingBannerMapper(includesForeignSigners: true)

        fastTradingSubscription = fastTrading.statePublisher
            .combineLatest(fastTrading.bannerDismissalsPublisher)
            .map { state, dismissals in
                FastTradingUpdate(banner: mapper.mapToBanner(state: state, dismissals: dismissals), isSettled: state != .loading)
            }
            .removeDuplicates()
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, update in
                viewModel.apply(update)
            }

        Task { await fastTrading.refresh() }
    }

    func apply(_ update: FastTradingUpdate) {
        fastTradingBanner = update.banner

        if update.isSettled {
            revealContent()
        }
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

// MARK: - Content reveal

private extension PolymarketMainViewModel {
    func scheduleRevealTimeout() {
        guard !isContentRevealed else { return }

        revealTimeoutTask = Task { @MainActor [weak self, revealDelayProvider] in
            try? await revealDelayProvider.wait(for: Constants.revealTimeout)

            guard !Task.isCancelled else { return }

            self?.revealContent()
        }
    }

    func revealContent() {
        guard !isContentRevealed else { return }

        revealTimeoutTask?.cancel()
        revealTimeoutTask = nil
        isContentRevealed = true
    }
}

// MARK: - Types

private extension PolymarketMainViewModel {
    struct FastTradingUpdate: Equatable {
        let banner: PolymarketFastTradingBanner?
        let isSettled: Bool
    }

    enum Constants {
        static let revealTimeout: TimeInterval = 1.5
    }
}
