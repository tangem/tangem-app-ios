//
//  PolymarketOrderSummaryViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation
import TangemLocalization
import TangemPolymarket
import TangemPolymarketUI

@MainActor
final class PolymarketOrderSummaryViewModel: ObservableObject {
    // MARK: - View state

    @Published private(set) var header: PolymarketOrderSummaryHeader.Model
    @Published private(set) var feeText: String
    @Published private(set) var slippageText: String
    @Published private(set) var notifications: [PolymarketOrderNotification] = []
    @Published private(set) var isPlaceEnabled = false
    @Published private(set) var isFeeBreakdownAvailable = false

    // MARK: - Content

    let marketRow: PolymarketOrderMarketRow.Model
    let currencyCode = PolymarketUtilities.collateralTokenItem.currencySymbol

    // MARK: - Dependencies

    private let model: PolymarketOrderModel
    private weak var coordinator: PolymarketOrderSummaryRoutable?

    private var bag: Set<AnyCancellable> = []

    // MARK: - Init

    init(model: PolymarketOrderModel, coordinator: PolymarketOrderSummaryRoutable?) {
        self.model = model
        self.coordinator = coordinator

        marketRow = .make(market: model.market, outcome: model.outcome)
        header = Self.makeHeader(state: model.state)
        feeText = Self.makeFeeText(state: model.state)
        slippageText = PolymarketSlippageFormatter.rowText(model.state.slippagePercent)

        bind()
    }

    // MARK: - View actions

    func handleViewAction(_ action: ViewAction) {
        switch action {
        case .appeared:
            model.handleViewAction(.screenAppeared)
        case .disappeared:
            model.handleViewAction(.screenDisappeared)
        case .backTapped:
            coordinator?.closeSummary()
        case .closeTapped:
            coordinator?.closeOrder()
        case .placeTapped:
            // [REDACTED_TODO_COMMENT]
            coordinator?.openResult()
        case .feeTapped:
            openFeeBreakdown()
        case .legalTermsTapped(let url):
            coordinator?.openLegalTerms(url: url)
        case .quoteRetryTapped:
            model.handleViewAction(.quoteRetried)
        }
    }
}

// MARK: - ViewAction

extension PolymarketOrderSummaryViewModel {
    enum ViewAction {
        case appeared
        case disappeared
        case backTapped
        case closeTapped
        case placeTapped
        case feeTapped
        case legalTermsTapped(URL)
        case quoteRetryTapped
    }
}

// MARK: - Navigation

private extension PolymarketOrderSummaryViewModel {
    func openFeeBreakdown() {
        guard isFeeBreakdownAvailable else { return }

        coordinator?.openFeeBreakdown(model: model)
    }
}

// MARK: - Binding

private extension PolymarketOrderSummaryViewModel {
    func bind() {
        model
            .$state
            .removeDuplicates()
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, state in
                viewModel.update(with: state)
            }
            .store(in: &bag)
    }

    func update(with state: PolymarketOrderModel.State) {
        let gate = PolymarketOrderGate(state: state)

        header = Self.makeHeader(state: state)
        feeText = Self.makeFeeText(state: state)
        slippageText = PolymarketSlippageFormatter.rowText(state.slippagePercent)
        notifications = gate.notifications
        isPlaceEnabled = gate.isPrimaryButtonEnabled
        isFeeBreakdownAvailable = state.quote.quote != nil
    }
}

// MARK: - Mapping

private extension PolymarketOrderSummaryViewModel {
    static func makeHeader(state: PolymarketOrderModel.State) -> PolymarketOrderSummaryHeader.Model {
        .make(
            amountText: PolymarketOrderFormatter.enteredAmount(state.enteredAmount),
            balanceText: Localization.commonBalance(PolymarketOrderFormatter.collateralBalance(state.balance)),
            toWin: makeToWin(state: state)
        )
    }

    static func makeToWin(state: PolymarketOrderModel.State) -> PolymarketAmountBadge.State? {
        guard let quote = state.quote.quote else { return nil }

        return .value(PolymarketOrderFormatter.money(quote.expectedExecutionAmount))
    }

    static func makeFeeText(state: PolymarketOrderModel.State) -> String {
        PolymarketOrderFormatter.money(state.quote.quote?.fees.total)
    }
}
