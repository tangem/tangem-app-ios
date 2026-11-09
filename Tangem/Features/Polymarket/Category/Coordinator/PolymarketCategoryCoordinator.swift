//
//  PolymarketCategoryCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemPolymarket

final class PolymarketCategoryCoordinator: CoordinatorObject {
    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Root ViewModels

    @Published private(set) var rootViewModel: PolymarketCategoryViewModel?

    // MARK: - Child ViewModels

    @Published var destination: Destination?

    private var onRegionWarning: (() -> Void)?
    private var onActivateFastTrading: (@MainActor () -> Void)?
    private var onOpenSettings: (@MainActor () -> Void)?
    private weak var orderBuilder: PolymarketOrderFlowBuilder?
    private weak var eventBuilder: PolymarketEventDetailsBuilder?

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
        onActivateFastTrading = options.onActivateFastTrading
        onOpenSettings = options.onOpenSettings
        orderBuilder = options.orderBuilder
        eventBuilder = options.eventBuilder

        Task { @MainActor in
            rootViewModel = PolymarketCategoryViewModel(
                category: options.category,
                eventsViewModel: options.makeEventsViewModel(self),
                refreshCenter: options.refreshCenter,
                fastTradingService: options.fastTradingService,
                coordinator: self
            )
        }
    }
}

// MARK: - Options

extension PolymarketCategoryCoordinator {
    struct Options {
        let category: PolymarketCategory
        let refreshCenter: PolymarketMainRefreshCenter
        let makeEventsViewModel: @MainActor (PolymarketEventOpeningRoutable) -> PolymarketEventsBlockViewModel
        let fastTradingService: PolymarketFastTradingServicing?
        let onRegionWarning: () -> Void
        let onActivateFastTrading: @MainActor () -> Void
        let onOpenSettings: @MainActor () -> Void
        let orderBuilder: PolymarketOrderFlowBuilder
        let eventBuilder: PolymarketEventDetailsBuilder
    }

    enum Destination {
        case eventDetails(PolymarketEventDetailsCoordinator)
        case positionDetails(PolymarketPositionDetailsCoordinator)
    }
}

// MARK: - PolymarketCategoryRoutable protocol conformance

extension PolymarketCategoryCoordinator: PolymarketCategoryRoutable {
    func closeCategory() {
        dismiss()
    }

    @MainActor
    func openSettings() {
        onOpenSettings?()
    }

    @MainActor
    func openFastTradingActivation() {
        onActivateFastTrading?()
    }
}

// MARK: - PolymarketEventOpeningRoutable protocol conformance

extension PolymarketCategoryCoordinator: PolymarketEventOpeningRoutable {
    func openRegionWarning() {
        onRegionWarning?()
    }

    func openEventDetails(
        eventID: String,
        placeholder: PolymarketEventPlaceholder?,
        category: PolymarketCategory?,
        onOrderPlaced: @escaping @MainActor (PolymarketOrderIndexing) -> Void
    ) {
        guard let eventBuilder else { return }

        destination = .eventDetails(eventBuilder.makeEventDetailsCoordinator(
            eventID: eventID,
            placeholder: placeholder,
            category: category,
            onOrderPlaced: onOrderPlaced,
            onRegionWarning: { [weak self] in self?.onRegionWarning?() },
            onClose: { [weak self] in self?.popToCategory() }
        ))
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

// MARK: - Navigation

extension PolymarketCategoryCoordinator {
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

        guard let coordinator = orderBuilder?.makePositionDetailsAfterOrder(
            position: position,
            onOrderPlaced: onPlaced,
            onRegionWarning: { [weak self] in self?.onRegionWarning?() }
        ) else {
            return
        }

        destination = .positionDetails(coordinator)
    }

    func popToCategory() {
        destination = nil
    }
}
