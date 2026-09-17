//
//  PolymarketDestinationFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemPolymarket

final class PolymarketDestinationFactory {
    private let dependencies: PolymarketMainDependencies
    private let onAddFunds: () -> Void

    init(dependencies: PolymarketMainDependencies, onAddFunds: @escaping () -> Void) {
        self.dependencies = dependencies
        self.onAddFunds = onAddFunds
    }

    func makeEventDetails(
        eventID: String,
        category: PolymarketCategory?,
        onOrderPlaced: @escaping @MainActor (PolymarketOrderIndexing) -> Void,
        onRegionWarning: @escaping () -> Void,
        onOpenPosition: @escaping (PolymarketPosition) -> Void,
        onClose: @escaping Action<Void>
    ) -> PolymarketEventDetailsCoordinator {
        let coordinator = PolymarketEventDetailsCoordinator(dismissAction: onClose)

        coordinator.start(with: .init(
            eventID: eventID,
            category: category,
            apiProvider: dependencies.apiProvider,
            geoblockStateProvider: dependencies.geoblockStateProvider,
            onOrderPlaced: onOrderPlaced,
            onRegionWarning: onRegionWarning,
            onOpenPosition: onOpenPosition,
            orderBuilder: self
        ))

        return coordinator
    }

    func makePositionDetails(
        position: PolymarketPosition,
        onOrderPlaced: @escaping @MainActor (PolymarketOrderIndexing) -> Void,
        onRegionWarning: @escaping () -> Void,
        onOpenPosition: @escaping (PolymarketPosition) -> Void,
        onClose: @escaping Action<Void>
    ) -> PolymarketPositionDetailsCoordinator {
        let coordinator = PolymarketPositionDetailsCoordinator(dismissAction: onClose)

        coordinator.start(with: .init(
            position: position,
            apiProvider: dependencies.apiProvider,
            geoblockStateProvider: dependencies.geoblockStateProvider,
            onOrderPlaced: onOrderPlaced,
            onRegionWarning: onRegionWarning,
            onOpenPosition: onOpenPosition,
            orderBuilder: self
        ))

        return coordinator
    }

    func makeMyPositions(
        tab: PolymarketPositionsTab,
        onOrderPlaced: @escaping @MainActor (PolymarketOrderIndexing) -> Void,
        onClaimed: @escaping () -> Void,
        onRegionWarning: @escaping () -> Void,
        onClose: @escaping Action<Void>
    ) -> PolymarketMyPositionsCoordinator {
        let coordinator = PolymarketMyPositionsCoordinator(dismissAction: onClose)

        coordinator.start(with: .init(
            tab: tab,
            positionsService: dependencies.positionsService,
            apiProvider: dependencies.apiProvider,
            geoblockStateProvider: dependencies.geoblockStateProvider,
            redeemService: dependencies.redeemService,
            onRegionWarning: onRegionWarning,
            onOrderPlaced: onOrderPlaced,
            onClaimed: onClaimed,
            orderBuilder: self
        ))

        return coordinator
    }
}

// MARK: - PolymarketOrderFlowBuilder protocol conformance

extension PolymarketDestinationFactory: PolymarketOrderFlowBuilder {
    func makeOrderCoordinator(
        market: PolymarketMarket,
        outcome: PolymarketOutcome,
        eventTitle: String,
        request: PolymarketOrderRequest,
        onPlaced: @escaping @MainActor (PolymarketOrderIndexing) -> Void,
        onOpenPosition: @escaping (PolymarketPosition) -> Void,
        onClose: @escaping () -> Void
    ) -> PolymarketOrderCoordinator {
        let coordinator = PolymarketOrderCoordinator(
            dismissAction: { payload in
                guard let payload else {
                    onClose()
                    return
                }

                if let position = payload.position {
                    onOpenPosition(position)
                } else {
                    onClose()
                }

                Task { @MainActor in
                    onPlaced(payload.indexing)
                }
            }
        )

        coordinator.start(with: .init(
            market: market,
            outcome: outcome,
            eventTitle: eventTitle,
            walletId: dependencies.walletId,
            intent: dependencies.makeOrderIntent(for: request),
            geoblockStateProvider: dependencies.geoblockStateProvider,
            placementService: dependencies.placementService,
            positionsService: dependencies.positionsService,
            isAwaitingFundsPublisher: dependencies.fundsArrivalTracker.$isAwaitingFunds.eraseToAnyPublisher(),
            onAddFunds: onAddFunds
        ))

        return coordinator
    }
}
