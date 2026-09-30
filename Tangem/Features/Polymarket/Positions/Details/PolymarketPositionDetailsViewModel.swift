//
//  PolymarketPositionDetailsViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation
import TangemLocalization
import TangemPolymarket
import TangemPolymarketUI
import TangemUIUtils

final class PolymarketPositionDetailsViewModel: ObservableObject, Identifiable {
    @Published var hint: PolymarketPositionHintSheetView.Model?
    @Published var alert: AlertBinder?
    @Published private(set) var loadingSide: PolymarketOrderSide?

    var model: PolymarketPositionDetailsView.Model {
        .make(
            position: position,
            openEventDetails: { [weak self] in self?.onMarketTap() },
            onClosePosition: { [weak self] in self?.onOrderTap(.sell) },
            onBuy: { [weak self] in self?.onOrderTap(.buy) },
            onHint: { [weak self] hint in self?.hint = hint },
            loadingSide: loadingSide
        )
    }

    @Published private(set) var position: PolymarketPosition
    private let apiProvider: PolymarketAPIProvider
    private let positionsService: PolymarketPositionsService
    private let geoblockStateProvider: PolymarketGeoblockStateProvider
    private let onOrderPlaced: @MainActor (PolymarketOrderIndexing) -> Void
    private weak var coordinator: PolymarketPositionDetailsRoutable?

    private var orderTask: Task<Void, Never>?
    private var refreshTask: Task<Void, Never>?

    init(
        position: PolymarketPosition,
        apiProvider: PolymarketAPIProvider,
        positionsService: PolymarketPositionsService,
        geoblockStateProvider: PolymarketGeoblockStateProvider,
        onOrderPlaced: @escaping @MainActor (PolymarketOrderIndexing) -> Void,
        coordinator: PolymarketPositionDetailsRoutable
    ) {
        self.position = position
        self.apiProvider = apiProvider
        self.positionsService = positionsService
        self.geoblockStateProvider = geoblockStateProvider
        self.onOrderPlaced = onOrderPlaced
        self.coordinator = coordinator
    }

    func onCloseTap() {
        coordinator?.closePositionDetails()
    }

    func onDisappear() {
        orderTask?.cancel()
        orderTask = nil
        loadingSide = nil
    }

    deinit {
        refreshTask?.cancel()
    }
}

// MARK: - Trading readiness

extension PolymarketPositionDetailsViewModel {
    enum TradableRequest {
        case ready(PolymarketOrderRequest)
        case marketClosed
        case positionGone
    }
}

// MARK: - The market the position belongs to

private extension PolymarketPositionDetailsViewModel {
    private func onMarketTap() {
        guard let eventId = position.eventId else { return }

        coordinator?.openEventDetails(
            eventID: eventId,
            category: nil,
            onOrderPlaced: { [weak self] indexing in
                self?.onOrderPlaced(indexing)
                self?.follow(indexing)
            }
        )
    }

    func tradableRequest(for side: PolymarketOrderSide) async throws -> TradableRequest {
        let refreshed = try await positionsService.position(
            conditionId: position.conditionId,
            assetId: position.assetId
        )

        try Task.checkCancellation()

        guard let refreshed else { return .positionGone }

        position = refreshed

        guard refreshed.resolutionStatus == .open, refreshed.isAcceptingOrders else { return .marketClosed }

        switch side {
        case .buy:
            return .ready(.buy)
        case .sell:
            return refreshed.isEmptied ? .positionGone : .ready(.sell(shares: refreshed.size))
        }
    }

    func onOrderTap(_ side: PolymarketOrderSide) {
        guard orderTask == nil else { return }

        guard geoblockStateProvider.state != .blocked else {
            coordinator?.openRegionWarning()
            return
        }

        loadingSide = side

        orderTask = runTask(in: self) { @MainActor viewModel in
            defer {
                viewModel.orderTask = nil
                viewModel.loadingSide = nil
            }

            do {
                let request: PolymarketOrderRequest

                switch try await viewModel.tradableRequest(for: side) {
                case .ready(let tradable):
                    request = tradable
                case .marketClosed:
                    viewModel.coordinator?.openMarketClosed()
                    return
                case .positionGone:
                    viewModel.coordinator?.closePositionDetails()
                    return
                }

                let (market, outcome, eventTitle) = try await viewModel.market()
                try Task.checkCancellation()

                viewModel.coordinator?.openOrder(
                    market: market,
                    outcome: outcome,
                    eventTitle: eventTitle,
                    request: request,
                    onPlaced: { [weak viewModel] indexing in
                        viewModel?.onOrderPlaced(indexing)
                        viewModel?.follow(indexing)
                    }
                )
            } catch {
                guard !error.isCancellationError else { return }

                PolymarketLogger.error("Failed to open the order for a held position", error: error)
                viewModel.alert = AlertBuilder.makeOkGotItAlert(message: Localization.commonUnknownError)
            }
        }
    }

    func follow(_ indexing: PolymarketOrderIndexing) {
        refreshTask?.cancel()

        refreshTask = runTask(in: self) { @MainActor viewModel in
            let updated = await indexing.value

            guard !Task.isCancelled else { return }

            guard let updated, updated.id == viewModel.position.id else { return }

            guard updated.size > 0 else {
                viewModel.coordinator?.closePositionDetails()
                return
            }

            viewModel.position = updated
        }
    }

    func market() async throws -> (PolymarketMarket, PolymarketOutcome, String) {
        guard let eventId = position.eventId, let marketId = position.marketId else {
            throw PositionDetailsError.positionWithoutMarket
        }

        let event = try await apiProvider.event(id: eventId)

        guard
            let market = event.markets.first(where: { $0.id == marketId }),
            let outcome = market.outcomes.first(where: { $0.assetId == position.assetId })
        else {
            throw PositionDetailsError.positionWithoutMarket
        }

        return (market, outcome, event.title)
    }

    enum PositionDetailsError: Error {
        case positionWithoutMarket
    }
}
