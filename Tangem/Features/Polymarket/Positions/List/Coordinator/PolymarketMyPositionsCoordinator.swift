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
    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Root ViewModels

    @Published private(set) var rootViewModel: PolymarketMyPositionsViewModel?

    // MARK: - Child ViewModels

    @Published var destination: Destination?

    private var apiProvider: PolymarketAPIProvider?
    private var positionsService: PolymarketPositionsService?
    private var geoblockStateProvider: PolymarketGeoblockStateProvider?
    private var redeemService: PolymarketRedeeming?
    private var onRegionWarning: (() -> Void)?
    private var onOrderPlaced: (@MainActor (PolymarketOrderIndexing) -> Void)?
    private var onClaimed: ((PolymarketPosition?) -> Void)?
    private weak var orderBuilder: PolymarketOrderFlowBuilder?
    private weak var eventBuilder: PolymarketEventDetailsBuilder?

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
        positionsService = options.positionsService
        geoblockStateProvider = options.geoblockStateProvider
        redeemService = options.redeemService
        onRegionWarning = options.onRegionWarning
        onOrderPlaced = options.onOrderPlaced
        onClaimed = options.onClaimed
        orderBuilder = options.orderBuilder
        eventBuilder = options.eventBuilder

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
        let onClaimed: (PolymarketPosition?) -> Void
        let orderBuilder: PolymarketOrderFlowBuilder
        let eventBuilder: PolymarketEventDetailsBuilder
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
    func openRedeem(position: PolymarketPosition, onClaimed: @escaping (PolymarketPosition?) -> Void) {
        guard let redeemService else { return }

        destination = .redeem(PolymarketRedeemViewModel(
            position: position,
            redeemService: redeemService,
            onClaimed: { [weak self] claimed in
                onClaimed(claimed)
                self?.onClaimed?(claimed)
            },
            coordinator: self
        ))
    }

    func openPositionDetails(position: PolymarketPosition, onOrderPlaced: @escaping @MainActor (PolymarketOrderIndexing) -> Void) {
        guard destination == nil else {
            destination = nil

            Task { @MainActor [weak self] in
                self?.openPositionDetails(position: position, onOrderPlaced: onOrderPlaced)
            }
            return
        }

        guard let apiProvider, let positionsService, let geoblockStateProvider, let orderBuilder, let eventBuilder else { return }

        let coordinator = PolymarketPositionDetailsCoordinator(
            dismissAction: { [weak self] in self?.popToPositions() }
        )

        coordinator.start(with: .init(
            position: position,
            apiProvider: apiProvider,
            positionsService: positionsService,
            geoblockStateProvider: geoblockStateProvider,
            onOrderPlaced: { [weak self] indexing in
                onOrderPlaced(indexing)
                self?.onOrderPlaced?(indexing)
            },
            onRegionWarning: { [weak self] in self?.onRegionWarning?() },
            orderBuilder: orderBuilder,
            eventBuilder: eventBuilder
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
