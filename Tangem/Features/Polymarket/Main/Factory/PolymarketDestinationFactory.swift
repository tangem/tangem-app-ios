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
    private let onRegionWarning: () -> Void
    private let onReturnToMain: () -> Void

    init(
        dependencies: PolymarketMainDependencies,
        onAddFunds: @escaping () -> Void,
        onRegionWarning: @escaping () -> Void,
        onReturnToMain: @escaping () -> Void
    ) {
        self.dependencies = dependencies
        self.onAddFunds = onAddFunds
        self.onRegionWarning = onRegionWarning
        self.onReturnToMain = onReturnToMain
    }

    func returnToMain() {
        onReturnToMain()
    }

    func makePositionDetails(
        position: PolymarketPosition,
        onOrderPlaced: @escaping @MainActor (PolymarketOrderIndexing) -> Void,
        onRegionWarning: @escaping () -> Void,
        onClose: @escaping Action<Void>
    ) -> PolymarketPositionDetailsCoordinator {
        let coordinator = PolymarketPositionDetailsCoordinator(dismissAction: onClose)

        coordinator.start(with: .init(
            position: position,
            apiProvider: dependencies.apiProvider,
            positionsService: dependencies.positionsService,
            geoblockStateProvider: dependencies.geoblockStateProvider,
            onOrderPlaced: onOrderPlaced,
            onRegionWarning: onRegionWarning,
            orderBuilder: self,
            eventBuilder: self
        ))

        return coordinator
    }

    func makeMyPositions(
        tab: PolymarketPositionsTab,
        onOrderPlaced: @escaping @MainActor (PolymarketOrderIndexing) -> Void,
        onClaimed: @escaping (PolymarketPosition?) -> Void,
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
            orderBuilder: self,
            eventBuilder: self
        ))

        return coordinator
    }
}

// MARK: - PolymarketOrderFlowBuilder

extension PolymarketDestinationFactory: PolymarketOrderFlowBuilder {
    func makeOrderCoordinator(
        market: PolymarketMarket,
        outcome: PolymarketOutcome,
        eventTitle: String,
        request: PolymarketOrderRequest,
        pushesPlacedPosition: Bool,
        onPlaced: @escaping @MainActor (PolymarketOrderIndexing) -> Void,
        onOpenPosition: @escaping (PolymarketPosition) -> Void,
        onClose: @escaping () -> Void
    ) -> PolymarketOrderCoordinator {
        let coordinator = PolymarketOrderCoordinator(
            dismissAction: { [weak self] payload in
                guard let payload else {
                    onClose()
                    return
                }

                if let position = payload.position {
                    onOpenPosition(position)
                } else if payload.returnsToMain {
                    self?.onReturnToMain()
                } else {
                    onClose()
                }
            }
        )

        coordinator.start(with: .init(
            market: market,
            outcome: outcome,
            eventTitle: eventTitle,
            walletId: dependencies.walletId,
            account: dependencies.orderAccount,
            intent: dependencies.makeOrderIntent(for: request),
            geoblockStateProvider: dependencies.geoblockStateProvider,
            placementService: dependencies.placementService,
            positionsService: dependencies.positionsService,
            clobService: dependencies.clobService,
            isAwaitingFundsPublisher: dependencies.fundsArrivalTracker.$isAwaitingFunds.eraseToAnyPublisher(),
            collateralBalancePublisher: dependencies.balanceProvider.collateralBalancePublisher.map(\.value).eraseToAnyPublisher(),
            addFundsReadinessStream: dependencies.accountFundsInteractor.makeStateStream(),
            positionBuilder: pushesPlacedPosition ? self : nil,
            onPlaced: onPlaced,
            onRegionWarning: onRegionWarning,
            onAddFunds: onAddFunds
        ))

        return coordinator
    }
}

extension PolymarketDestinationFactory: PolymarketEventDetailsBuilder {
    func makeEventDetailsCoordinator(
        eventID: String,
        category: PolymarketCategory?,
        onOrderPlaced: @escaping @MainActor (PolymarketOrderIndexing) -> Void,
        onRegionWarning: @escaping () -> Void,
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
            orderBuilder: self
        ))

        return coordinator
    }
}
