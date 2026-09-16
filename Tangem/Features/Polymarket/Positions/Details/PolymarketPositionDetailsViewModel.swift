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
    @Published private(set) var isOrderLoading = false

    var model: PolymarketPositionDetailsView.Model {
        .make(
            position: position,
            onClosePosition: { [weak self] in self?.coordinator?.closePositionDetails() },
            onBuy: { [weak self] in self?.onBuyTap() },
            onHint: { [weak self] hint in self?.hint = hint },
            isOrderLoading: isOrderLoading
        )
    }

    private let position: PolymarketPosition
    private let apiProvider: PolymarketAPIProvider
    private let geoblockStateProvider: PolymarketGeoblockStateProvider?
    private let onOrderPlaced: @MainActor (Task<Void, Never>?) -> Void
    private weak var coordinator: PolymarketPositionDetailsRoutable?

    private var orderTask: Task<Void, Never>?

    init(
        position: PolymarketPosition,
        apiProvider: PolymarketAPIProvider,
        geoblockStateProvider: PolymarketGeoblockStateProvider?,
        onOrderPlaced: @escaping @MainActor (Task<Void, Never>?) -> Void,
        coordinator: PolymarketPositionDetailsRoutable
    ) {
        self.position = position
        self.apiProvider = apiProvider
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
        isOrderLoading = false
    }
}

// MARK: - The market the position belongs to

private extension PolymarketPositionDetailsViewModel {
    func onBuyTap() {
        guard orderTask == nil else { return }

        guard geoblockStateProvider?.state != .blocked else {
            coordinator?.openRegionWarning()
            return
        }

        isOrderLoading = true

        orderTask = runTask(in: self) { @MainActor viewModel in
            defer {
                viewModel.orderTask = nil
                viewModel.isOrderLoading = false
            }

            do {
                let (market, outcome, eventTitle) = try await viewModel.market()
                try Task.checkCancellation()

                viewModel.coordinator?.openOrder(
                    market: market,
                    outcome: outcome,
                    eventTitle: eventTitle,
                    onPlaced: viewModel.onOrderPlaced
                )
            } catch {
                guard !error.isCancellationError else { return }

                PolymarketLogger.error("Failed to open the order for a held position", error: error)
                viewModel.alert = AlertBuilder.makeOkGotItAlert(message: Localization.commonUnknownError)
            }
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
