//
//  PolymarketPositionDetailsCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemPolymarket
import TangemPolymarketUI

final class PolymarketPositionDetailsCoordinator: CoordinatorObject {
    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: FloatingSheetPresenter

    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Root ViewModels

    @Published private(set) var rootViewModel: PolymarketPositionDetailsViewModel?

    // MARK: - Child ViewModels

    @Published var destination: Destination?

    private var onRegionWarning: (() -> Void)?
    private weak var orderBuilder: PolymarketOrderFlowBuilder?

    var orderPresenter: PolymarketOrderPresenter? {
        orderBuilder?.orderPresenter
    }

    private weak var eventBuilder: PolymarketEventDetailsBuilder?
    var disablesPopGesture = false

    private var closesWhenFlowDismissed = false
    private var hasLeftScreen = false

    // MARK: - Init

    required init(
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions> = { _ in }
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        onRegionWarning = options.onRegionWarning
        orderBuilder = options.orderBuilder
        eventBuilder = options.eventBuilder

        rootViewModel = PolymarketPositionDetailsViewModel(
            position: options.position,
            apiProvider: options.apiProvider,
            positionsService: options.positionsService,
            geoblockStateProvider: options.geoblockStateProvider,
            onOrderPlaced: options.onOrderPlaced,
            coordinator: self
        )
    }
}

// MARK: - Options

extension PolymarketPositionDetailsCoordinator {
    struct Options {
        let position: PolymarketPosition
        let apiProvider: PolymarketAPIProvider
        let positionsService: PolymarketPositionsService
        let geoblockStateProvider: PolymarketGeoblockStateProvider
        let onOrderPlaced: @MainActor (PolymarketOrderIndexing) -> Void
        let onRegionWarning: () -> Void
        let orderBuilder: PolymarketOrderFlowBuilder
        let eventBuilder: PolymarketEventDetailsBuilder
    }

    enum Destination {
        case eventDetails(PolymarketEventDetailsCoordinator)
    }
}

// MARK: - Navigation

extension PolymarketPositionDetailsCoordinator {
    func popToPositionDetails() {
        if closesWhenFlowDismissed {
            closesWhenFlowDismissed = false
            dismiss()
            return
        }

        destination = nil
    }
}

// MARK: - PolymarketPositionDetailsRoutable protocol conformance

extension PolymarketPositionDetailsCoordinator: PolymarketPositionDetailsRoutable {
    func leaveSoldPosition() {
        leaveScreen()
    }

    func closePositionDetails() {
        guard destination == nil else {
            closesWhenFlowDismissed = true
            return
        }

        leaveScreen()
    }

    func openRegionWarning() {
        onRegionWarning?()
    }

    @MainActor
    func openMarketClosed() {
        floatingSheetPresenter.enqueue(sheet: PolymarketRegionRestrictionViewModel.marketClosed(
            onClose: { [weak self] in self?.floatingSheetPresenter.removeActiveSheet() }
        ))
    }

    func openEventDetails(
        eventID: String,
        category: PolymarketCategory?,
        onOrderPlaced: @escaping @MainActor (PolymarketOrderIndexing) -> Void
    ) {
        guard let coordinator = eventBuilder?.makeEventDetailsCoordinator(
            eventID: eventID,
            category: category,
            onOrderPlaced: onOrderPlaced,
            onRegionWarning: openRegionWarning,
            onClose: { [weak self] in self?.popToPositionDetails() }
        ) else {
            return
        }

        destination = .eventDetails(coordinator)
    }

    func openOrder(
        market: PolymarketMarket,
        outcome: PolymarketOutcome,
        eventTitle: String,
        request: PolymarketOrderRequest,
        onPlaced: @escaping @MainActor (PolymarketOrderIndexing) -> Void
    ) {
        guard let orderBuilder else { return }

        let coordinator = orderBuilder.makeOrderCoordinator(
            market: market,
            outcome: outcome,
            eventTitle: eventTitle,
            request: request,
            onPlaced: onPlaced,
            onOpenPosition: { [weak orderBuilder] _ in orderBuilder?.dismissOrder() },
            onClose: { [weak orderBuilder] in orderBuilder?.dismissOrder() }
        )
        coordinator.offersPlacedPosition = false
        coordinator.onPositionClosed = { [weak self, weak orderBuilder] in
            orderBuilder?.runAfterOrderDismiss { [weak self] in self?.leaveSoldPosition() }
        }
        coordinator.onLeaveClosedPosition = { [weak self] in self?.leaveSoldPosition() }

        orderBuilder.presentOrder(coordinator, from: self)
    }
}

// MARK: - Leaving

private extension PolymarketPositionDetailsCoordinator {
    func leaveScreen() {
        guard !hasLeftScreen else { return }

        hasLeftScreen = true
        orderPresenter?.dismiss(presentedFrom: self)
        dismiss()
    }
}
