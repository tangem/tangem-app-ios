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
    private var redeemService: PolymarketRedeeming?
    private var onRegionWarning: (() -> Void)?
    private var onOrderPlaced: (@MainActor (PolymarketOrderIndexing) -> Void)?
    private var onClaimed: (() -> Void)?
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
        redeemService = options.redeemService
        onRegionWarning = options.onRegionWarning
        onOrderPlaced = options.onOrderPlaced
        onClaimed = options.onClaimed
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
        let geoblockStateProvider: PolymarketGeoblockStateProvider
        let redeemService: PolymarketRedeeming
        let onRegionWarning: () -> Void
        let onOrderPlaced: @MainActor (PolymarketOrderIndexing) -> Void
        let onClaimed: () -> Void
        let orderBuilder: PolymarketOrderFlowBuilder
    }

    enum Destination {
        case positionDetails(PolymarketPositionDetailsCoordinator)
        case redeem(PolymarketRedeemViewModel)
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

    @MainActor
    func openRedeem(position: PolymarketPosition, onClaimed: @escaping () -> Void) {
        guard let redeemService else { return }

        guard let viewModel = PolymarketRedeemViewModel(
            position: position,
            redeemService: redeemService,
            onClaimed: { [weak self] in
                onClaimed()
                self?.onClaimed?()
            },
            coordinator: self
        ) else {
            return
        }

        destination = .redeem(viewModel)
    }

    func openPositionDetails(position: PolymarketPosition, onOrderPlaced: @escaping @MainActor (PolymarketOrderIndexing) -> Void) {
        guard let apiProvider, let geoblockStateProvider, let orderBuilder else { return }

        let coordinator = PolymarketPositionDetailsCoordinator(
            dismissAction: { [weak self] in self?.popToPositions() }
        )

        coordinator.start(with: .init(
            position: position,
            apiProvider: apiProvider,
            geoblockStateProvider: geoblockStateProvider,
            onOrderPlaced: { [weak self] indexing in
                onOrderPlaced(indexing)
                self?.onOrderPlaced?(indexing)
            },
            onRegionWarning: { [weak self] in self?.onRegionWarning?() },
            onOpenPosition: { [weak self] position in
                self?.openPositionDetails(position: position, onOrderPlaced: onOrderPlaced)
            },
            orderBuilder: orderBuilder
        ))

        destination = .positionDetails(coordinator)
    }
}

// MARK: - PolymarketRedeemRoutable protocol conformance

extension PolymarketMyPositionsCoordinator: PolymarketRedeemRoutable {
    func closeRedeem() {
        popToPositions()
    }
}

// MARK: - Navigation

extension PolymarketMyPositionsCoordinator {
    func popToPositions() {
        destination = nil
    }
}
