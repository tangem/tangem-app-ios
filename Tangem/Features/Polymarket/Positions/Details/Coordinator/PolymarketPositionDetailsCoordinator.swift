//
//  PolymarketPositionDetailsCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemPolymarket

final class PolymarketPositionDetailsCoordinator: CoordinatorObject {
    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Root ViewModels

    @Published private(set) var rootViewModel: PolymarketPositionDetailsViewModel?

    // MARK: - Child ViewModels

    @Published var destination: Destination?

    private var onRegionWarning: (() -> Void)?
    private weak var orderBuilder: PolymarketOrderFlowBuilder?
    private weak var eventBuilder: PolymarketEventDetailsBuilder?
    private var closesWhenFlowDismissed = false

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
        let geoblockStateProvider: PolymarketGeoblockStateProvider
        let onOrderPlaced: @MainActor (PolymarketOrderIndexing) -> Void
        let onRegionWarning: () -> Void
        let orderBuilder: PolymarketOrderFlowBuilder
        let eventBuilder: PolymarketEventDetailsBuilder
    }

    enum Destination {
        case order(PolymarketOrderCoordinator)
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
    func closePositionDetails() {
        guard destination == nil else {
            closesWhenFlowDismissed = true
            return
        }

        dismiss()
    }

    func openRegionWarning() {
        onRegionWarning?()
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
        guard let coordinator = orderBuilder?.makeOrderCoordinator(
            market: market,
            outcome: outcome,
            eventTitle: eventTitle,
            request: request,
            pushesPlacedPosition: false,
            onPlaced: onPlaced,
            onOpenPosition: { [weak self] _ in self?.popToPositionDetails() },
            onClose: { [weak self] in self?.popToPositionDetails() }
        ) else {
            return
        }

        destination = .order(coordinator)
    }
}
