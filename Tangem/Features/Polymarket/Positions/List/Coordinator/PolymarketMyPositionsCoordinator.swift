//
//  PolymarketMyPositionsCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemPolymarket
import TangemStories

final class PolymarketMyPositionsCoordinator: CoordinatorObject {
    @Injected(\.tangemStoriesPresenter) private var tangemStoriesPresenter: any TangemStoriesPresenter

    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Root ViewModels

    @Published private(set) var rootViewModel: PolymarketMyPositionsViewModel?

    // MARK: - Child ViewModels

    @Published var destination: Destination?

    private var apiProvider: PolymarketAPIProvider?
    private var geoblockStateProvider: PolymarketGeoblockStateProvider?
    private var onRegionWarning: (() -> Void)?
    private var onOrderPlaced: (@MainActor (PolymarketOrderIndexing?) -> Void)?
    private weak var orderBuilder: PolymarketOrderFlowBuilder?

    // MARK: - Init

    required init(
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions> = { _ in }
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        apiProvider = options.apiProvider
        geoblockStateProvider = options.geoblockStateProvider
        onRegionWarning = options.onRegionWarning
        onOrderPlaced = options.onOrderPlaced
        orderBuilder = options.orderBuilder

        Task { @MainActor in
            rootViewModel = PolymarketMyPositionsViewModel(
                tab: options.tab,
                positionsService: options.positionsService,
                coordinator: self
            )
        }
    }
}

// MARK: - Options

extension PolymarketMyPositionsCoordinator {
    struct Options {
        let tab: PolymarketPositionsTab
        let positionsService: PolymarketPositionsService
        let apiProvider: PolymarketAPIProvider
        let geoblockStateProvider: PolymarketGeoblockStateProvider?
        let onRegionWarning: () -> Void
        let onOrderPlaced: @MainActor (PolymarketOrderIndexing?) -> Void
        let orderBuilder: PolymarketOrderFlowBuilder
    }

    enum Destination {
        case positionDetails(PolymarketPositionDetailsViewModel)
        case order(PolymarketOrderCoordinator)
    }
}

// MARK: - PolymarketMyPositionsRoutable protocol conformance

extension PolymarketMyPositionsCoordinator: PolymarketMyPositionsRoutable {
    func closeMyPositions() {
        dismiss()
    }

    @MainActor
    func openHowItWorks() {
        tangemStoriesPresenter.presentOnDemand(
            story: .polymarketOnboarding(.initialWithoutImages),
            analyticsSource: .predictions
        )
    }

    func openPositionDetails(position: PolymarketPosition, onOrderPlaced: @escaping @MainActor (PolymarketOrderIndexing?) -> Void) {
        guard let apiProvider else { return }

        destination = .positionDetails(PolymarketPositionDetailsViewModel(
            position: position,
            apiProvider: apiProvider,
            geoblockStateProvider: geoblockStateProvider,
            onOrderPlaced: { [weak self] indexing in
                onOrderPlaced(indexing)
                self?.onOrderPlaced?(indexing)
            },
            coordinator: self
        ))
    }
}

// MARK: - PolymarketPositionDetailsRoutable protocol conformance

extension PolymarketMyPositionsCoordinator: PolymarketPositionDetailsRoutable {
    func closePositionDetails() {
        destination = nil
    }

    func openRegionWarning() {
        onRegionWarning?()
    }

    func openOrder(
        market: PolymarketMarket,
        outcome: PolymarketOutcome,
        eventTitle: String,
        request: PolymarketOrderRequest,
        onPlaced: @escaping @MainActor (PolymarketOrderIndexing?) -> Void
    ) {
        guard let coordinator = orderBuilder?.makeOrderCoordinator(
            market: market,
            outcome: outcome,
            eventTitle: eventTitle,
            request: request,
            onPlaced: onPlaced,
            onOpenPosition: { [weak self] position in self?.openPositionDetails(position: position, onOrderPlaced: onPlaced) },
            onClose: { [weak self] in self?.destination = nil }
        ) else {
            return
        }

        destination = .order(coordinator)
    }
}
