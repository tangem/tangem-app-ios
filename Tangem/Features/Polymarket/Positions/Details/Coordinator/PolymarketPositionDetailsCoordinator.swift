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
    private var onOpenPosition: ((PolymarketPosition) -> Void)?
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
        onRegionWarning = options.onRegionWarning
        onOpenPosition = options.onOpenPosition
        orderBuilder = options.orderBuilder

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
        let onOpenPosition: (PolymarketPosition) -> Void
        let orderBuilder: PolymarketOrderFlowBuilder
    }

    enum Destination {
        case order(PolymarketOrderCoordinator)
    }
}

// MARK: - Navigation

extension PolymarketPositionDetailsCoordinator {
    func popToPositionDetails() {
        destination = nil
    }
}

// MARK: - PolymarketPositionDetailsRoutable protocol conformance

extension PolymarketPositionDetailsCoordinator: PolymarketPositionDetailsRoutable {
    func closePositionDetails() {
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
        guard let coordinator = orderBuilder?.makeOrderCoordinator(
            market: market,
            outcome: outcome,
            eventTitle: eventTitle,
            request: request,
            onPlaced: onPlaced,
            onOpenPosition: { [weak self] position in self?.onOpenPosition?(position) },
            onClose: { [weak self] in self?.popToPositionDetails() }
        ) else {
            return
        }

        destination = .order(coordinator)
    }
}
