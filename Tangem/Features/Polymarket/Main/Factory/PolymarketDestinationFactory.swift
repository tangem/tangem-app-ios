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
import TangemUI

final class PolymarketDestinationFactory {
    private let dependencies: PolymarketMainDependencies
    private let onAddFunds: () -> Void
    private let onRegionWarning: () -> Void
    private let onReturnToMain: () -> Void
    let orderPresenter: PolymarketOrderPresenter

    init(
        dependencies: PolymarketMainDependencies,
        onAddFunds: @escaping () -> Void,
        onRegionWarning: @escaping () -> Void,
        onReturnToMain: @escaping () -> Void,
        orderPresenter: PolymarketOrderPresenter
    ) {
        self.dependencies = dependencies
        self.onAddFunds = onAddFunds
        self.onRegionWarning = onRegionWarning
        self.onReturnToMain = onReturnToMain
        self.orderPresenter = orderPresenter
    }

    func returnToMain() {
        onReturnToMain()
    }

    func presentOrder(_ coordinator: PolymarketOrderCoordinator, from host: AnyObject?) {
        orderPresenter.present(coordinator, from: host)
    }

    func dismissOrder() {
        orderPresenter.dismiss()
    }

    func runAfterOrderDismiss(_ action: @escaping () -> Void) {
        orderPresenter.runAfterDismiss(action)
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

    func makeActivity(
        onRegionWarning: @escaping () -> Void,
        onClose: @escaping Action<Void>
    ) -> PolymarketActivityCoordinator {
        let coordinator = PolymarketActivityCoordinator(dismissAction: onClose)
        let activityHandler = dependencies.activityHandler

        coordinator.start(with: .init(
            activityService: dependencies.activityService,
            onOrderPlaced: { [weak activityHandler] indexing in activityHandler?.orderPlaced(awaiting: indexing) },
            onRegionWarning: onRegionWarning,
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
            signingButtonType: dependencies.signingButtonType,
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
        onPlaced: @escaping @MainActor (PolymarketOrderIndexing) -> Void,
        onOpenPosition: @escaping (PolymarketPosition) -> Void,
        onClose: @escaping () -> Void
    ) -> PolymarketOrderCoordinator {
        let coordinator = PolymarketOrderCoordinator(
            dismissAction: { payload in
                if let position = payload?.position {
                    onOpenPosition(position)
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
            signingButtonType: dependencies.signingButtonType,
            intent: dependencies.makeOrderIntent(for: request),
            geoblockStateProvider: dependencies.geoblockStateProvider,
            placementService: dependencies.placementService,
            positionsService: dependencies.positionsService,
            clobService: dependencies.clobService,
            isAwaitingFundsPublisher: dependencies.fundsArrivalTracker.$isAwaitingFunds.eraseToAnyPublisher(),
            collateralBalancePublisher: dependencies.balanceProvider.collateralBalancePublisher.map(\.value).eraseToAnyPublisher(),
            addFundsReadinessStream: dependencies.accountFundsInteractor.makeStateStream(),
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
