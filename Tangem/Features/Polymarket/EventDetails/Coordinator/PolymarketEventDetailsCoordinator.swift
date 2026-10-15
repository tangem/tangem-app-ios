//
//  PolymarketEventDetailsCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemPolymarket

final class PolymarketEventDetailsCoordinator: CoordinatorObject {
    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Root ViewModels

    @Published private(set) var rootViewModel: PolymarketEventDetailsViewModel?

    // MARK: - Child ViewModels

    @Published var destination: Destination?

    private var onRegionWarning: (() -> Void)?
    private weak var orderBuilder: PolymarketOrderFlowBuilder?

    var orderPresenter: PolymarketOrderPresenter? {
        orderBuilder?.orderPresenter
    }

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

        rootViewModel = PolymarketEventDetailsViewModel(
            eventID: options.eventID,
            category: options.category,
            apiProvider: options.apiProvider,
            geoblockStateProvider: options.geoblockStateProvider,
            onOrderPlaced: options.onOrderPlaced,
            coordinator: self
        )
    }
}

// MARK: - Options

extension PolymarketEventDetailsCoordinator {
    struct Options {
        let eventID: String
        let category: PolymarketCategory?
        let apiProvider: PolymarketAPIProvider
        let geoblockStateProvider: PolymarketGeoblockStateProvider
        let onOrderPlaced: @MainActor (PolymarketOrderIndexing) -> Void
        let onRegionWarning: () -> Void
        let orderBuilder: PolymarketOrderFlowBuilder
    }

    enum Destination {
        case positionDetails(PolymarketPositionDetailsCoordinator)
    }
}

// MARK: - Navigation

extension PolymarketEventDetailsCoordinator {
    func pushPositionDetails(
        _ position: PolymarketPosition,
        onPlaced: @escaping @MainActor (PolymarketOrderIndexing) -> Void
    ) {
        guard destination == nil else {
            destination = nil

            Task { @MainActor [weak self] in
                self?.pushPositionDetails(position, onPlaced: onPlaced)
            }
            return
        }

        guard let coordinator = orderBuilder?.makePositionDetails(
            position: position,
            onOrderPlaced: onPlaced,
            onRegionWarning: { [weak self] in self?.onRegionWarning?() },
            onClose: { [weak self] in self?.orderBuilder?.returnToMain() }
        ) else {
            return
        }

        coordinator.disablesPopGesture = true

        destination = .positionDetails(coordinator)
    }
}

// MARK: - PolymarketEventDetailsRoutable protocol conformance

extension PolymarketEventDetailsCoordinator: PolymarketEventDetailsRoutable {
    func dismissEventDetails() {
        dismiss()
    }

    func openRegionWarning() {
        onRegionWarning?()
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
            onOpenPosition: { [weak self, weak orderBuilder] position in
                self?.pushPositionDetails(position, onPlaced: onPlaced)
                orderBuilder?.dismissOrder()
            },
            onClose: { [weak orderBuilder] in orderBuilder?.dismissOrder() }
        )

        orderBuilder.presentOrder(coordinator, from: self)
    }
}
