//
//  PolymarketPositionsBlockViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemFoundation
import TangemPolymarket
import TangemPolymarketUI

@MainActor
final class PolymarketPositionsBlockViewModel: ObservableObject {
    @Published private(set) var content: Content = .hidden
    @Published private(set) var hasFinishedPositions = false

    private let loader: PolymarketPositionsLoader?
    private let presenceStore: PolymarketAccountPresenceStore
    private let userWalletId: UserWalletId
    private let activityHandler: PolymarketMainActivityHandler
    private let poller: PolymarketForegroundPoller
    private weak var routable: PolymarketPositionsBlockRoutable?

    private var state: State = .loading
    private var hadPositionsBefore = false
    private var isRetrying = false
    private var hasMorePositions = false
    private var openPositions: [PolymarketPosition] = []
    private var positionsGoneLocally: Set<String> = []

    private var loadTask: Task<Void, Never>?

    init(
        positionsService: PolymarketPositionsService?,
        presenceStore: PolymarketAccountPresenceStore,
        userWalletId: UserWalletId,
        refreshCenter: PolymarketMainRefreshCenter,
        activityHandler: PolymarketMainActivityHandler,
        routable: PolymarketPositionsBlockRoutable,
        notificationCenter: NotificationCenter = .default
    ) {
        loader = positionsService.map(PolymarketPositionsLoader.init(service:))
        self.presenceStore = presenceStore
        self.userWalletId = userWalletId
        self.activityHandler = activityHandler
        poller = PolymarketForegroundPoller(interval: Constants.pollingInterval, notificationCenter: notificationCenter)
        self.routable = routable

        refreshCenter.register { [weak self] scope in
            await self?.refresh(scope: scope)
        }
        activityHandler.setTradedHandler { [weak self] position in
            await self?.reload(applyingTraded: position)
        }
        activityHandler.setClaimedHandler { [weak self] position in
            await self?.reload(droppingClaimed: position)
        }

        load()
        startRefreshing()
    }

    deinit {
        loadTask?.cancel()
    }
}

// MARK: - View actions

extension PolymarketPositionsBlockViewModel {
    func handleViewAction(_ action: ViewAction) {
        switch action {
        case .openPositionDetails(let id):
            openPositionDetails(id: id)
        case .openMyPositions(let tab):
            openMyPositions(tab: tab)
        case .retry:
            load(userInitiated: true)
        }
    }

    enum ViewAction {
        case openPositionDetails(id: String)
        case openMyPositions(PolymarketPositionsTab)
        case retry
    }
}

// MARK: - Navigation

private extension PolymarketPositionsBlockViewModel {
    func openPositionDetails(id: String) {
        guard let position = openPositions.first(where: { $0.id == id }) else { return }

        let activityHandler = activityHandler

        guard !position.opensClaim else {
            routable?.openRedeem(position: position, onClaimed: { [weak activityHandler] claimed in
                activityHandler?.claimed(claimed)
            })
            return
        }

        routable?.openPositionDetails(position: position, onOrderPlaced: { [weak activityHandler] indexing in
            activityHandler?.orderPlaced(awaiting: indexing)
        })
    }

    func openMyPositions(tab: PolymarketPositionsTab) {
        let activityHandler = activityHandler

        routable?.openMyPositions(
            tab: tab,
            onOrderPlaced: { [weak activityHandler] indexing in activityHandler?.orderPlaced(awaiting: indexing) },
            onClaimed: { [weak activityHandler] claimed in activityHandler?.claimed(claimed) }
        )
    }
}

// MARK: - Refresh

private extension PolymarketPositionsBlockViewModel {
    func refresh(scope: PolymarketMainRefreshCenter.Scope) async {
        switch scope {
        case .full:
            load()
        case .balance, .accountFunds:
            break
        }
    }

    func reload(applyingTraded position: PolymarketPosition?) async {
        load()
        await loadTask?.value
        apply(traded: position)
    }

    func reload(droppingClaimed position: PolymarketPosition?) async {
        load()
        await loadTask?.value
        drop(claimed: position)
    }

    func startRefreshing() {
        guard loader != nil else { return }

        poller.start(
            onTick: { [weak self] in self?.load() },
            onPause: { [weak self] in self?.loadTask?.cancel() }
        )
    }
}

// MARK: - Loading

private extension PolymarketPositionsBlockViewModel {
    func load(userInitiated: Bool = false) {
        guard let loader else {
            state = .loaded
            updateContent()
            return
        }

        loadTask?.cancel()

        let isSilentRound = state == .failed && !userInitiated

        if state != .loaded, !isSilentRound {
            // Read once per round: the flag is written by this very load, and a mid-flight flip would
            // swap one state for another in front of the user.
            hadPositionsBefore = presenceStore.hadPositions(userWalletId: userWalletId)
            isRetrying = isRetrying || userInitiated

            withAnimation(.polymarketStateChange) {
                state = .loading
                updateContent()
            }
        }

        loadTask = runTask(in: self) { @MainActor viewModel in
            do {
                let snapshot = try await loader.load()
                try Task.checkCancellation()

                viewModel.apply(snapshot)
            } catch {
                guard !error.isCancellationError else { return }

                PolymarketLogger.error("Failed to load the open positions", error: error)

                viewModel.isRetrying = false

                withAnimation(.polymarketStateChange) {
                    if viewModel.state != .loaded {
                        viewModel.state = .failed
                    }

                    viewModel.updateContent()
                }
            }
        }
    }

    func apply(_ snapshot: PolymarketPositionsLoader.Snapshot) {
        openPositions = Array(stillOpen(snapshot.activePage.positions).prefix(Constants.positionsShown))
        hasMorePositions = snapshot.activePage.hasNext || snapshot.activePage.receivedCount > openPositions.count

        if let hasFinished = snapshot.hasFinishedPositions {
            hasFinishedPositions = hasFinished
        }

        isRetrying = false

        if snapshot.hasFinishedPositions == nil, openPositions.isEmpty, !hasFinishedPositions {
            withAnimation(.polymarketStateChange) {
                state = .failed
                updateContent()
            }
            return
        }

        if openPositions.isNotEmpty || hasFinishedPositions {
            presenceStore.markPositionsExisted(for: userWalletId)
            hadPositionsBefore = true
        }

        withAnimation(.polymarketStateChange) {
            state = .loaded
            updateContent()
        }
    }

    func stillOpen(_ positions: [PolymarketPosition]) -> [PolymarketPosition] {
        positionsGoneLocally.formIntersection(positions.map(\.id))

        return positions.filter { !positionsGoneLocally.contains($0.id) }
    }

    /// The list endpoint lags behind the traded outcome, so the reload can still hand back the pre-fill position.
    func apply(traded position: PolymarketPosition?) {
        guard let position else { return }

        if position.isEmptied {
            positionsGoneLocally.insert(position.id)
        }

        guard openPositions.contains(where: { $0.id == position.id }) else { return }

        openPositions = position.size > 0
            ? openPositions.map { $0.id == position.id ? position : $0 }
            : openPositions.filter { $0.id != position.id }

        state = .loaded
        updateContent()
    }

    /// The claimed shares are burned, but the list keeps handing the position back until the indexer notices.
    func drop(claimed position: PolymarketPosition?) {
        guard let position else { return }

        positionsGoneLocally.insert(position.id)

        guard openPositions.contains(where: { $0.id == position.id }) else { return }

        openPositions = openPositions.filter { $0.id != position.id }
        state = .loaded
        updateContent()
    }
}

// MARK: - Content

private extension PolymarketPositionsBlockViewModel {
    var skeletonRowCount: Int {
        presenceStore.shownPositionsCount(userWalletId: userWalletId) ?? Constants.defaultSkeletonRowCount
    }

    func rememberShownCount(_ count: Int) {
        guard presenceStore.shownPositionsCount(userWalletId: userWalletId) != count else { return }

        presenceStore.setShownPositionsCount(count, for: userWalletId)
    }

    func updateContent() {
        switch state {
        case .loading where hadPositionsBefore || isRetrying:
            content = .skeleton(rowCount: skeletonRowCount)
        case .loading:
            content = .hidden
        case .failed:
            content = .failed
        case .loaded where openPositions.isNotEmpty:
            rememberShownCount(openPositions.count)
            content = .positions(openPositions.map(PolymarketPositionRow.Model.make(position:)), showsViewAll: hasMorePositions)
        case .loaded where hadPositionsBefore:
            content = .noActivePositions(showsViewAll: hasMorePositions)
        case .loaded:
            content = .hidden
        }
    }
}

// MARK: - Types

extension PolymarketPositionsBlockViewModel {
    enum Content: Equatable {
        case hidden
        case skeleton(rowCount: Int)
        case failed
        case positions([PolymarketPositionRow.Model], showsViewAll: Bool)
        case noActivePositions(showsViewAll: Bool)
    }
}

private extension PolymarketPositionsBlockViewModel {
    enum State {
        case loading
        case loaded
        case failed
    }

    enum Constants {
        static let positionsShown = 3
        static let defaultSkeletonRowCount = 1
        static let pollingInterval: TimeInterval = 20
    }
}
