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
        let geoblockStateProvider: PolymarketGeoblockStateProvider?
        let onOrderPlaced: @MainActor (Task<Void, Never>?) -> Void
        let onRegionWarning: () -> Void
        let orderBuilder: PolymarketOrderFlowBuilder
    }

    enum Destination {
        case order(PolymarketOrderCoordinator)
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
        onPlaced: @escaping @MainActor (Task<Void, Never>?) -> Void
    ) {
        guard let coordinator = orderBuilder?.makeOrderCoordinator(
            market: market,
            outcome: outcome,
            eventTitle: eventTitle,
            onPlaced: onPlaced,
            onClose: { [weak self] in self?.destination = nil }
        ) else {
            return
        }

        destination = .order(coordinator)
    }
}
