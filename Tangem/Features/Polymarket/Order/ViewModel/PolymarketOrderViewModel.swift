//
//  PolymarketOrderViewModel.swift
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
final class PolymarketOrderViewModel: ObservableObject {
    // MARK: - View state

    @Published private(set) var payment: PolymarketOrderPaymentRow.Model
    @Published private(set) var slippageText: String
    @Published private(set) var amountCaption: AmountCaption?
    @Published private(set) var amountFractions: [PolymarketAmountFraction] = []
    @Published private(set) var notifications: [PolymarketOrderNotification] = []
    @Published private(set) var isAwaitingFunds = false
    @Published private(set) var isNextEnabled = false

    // MARK: - Content

    let marketRow: PolymarketOrderMarketRow.Model
    let fieldViewModel: DecimalNumberTextFieldViewModel

    // MARK: - Dependencies

    private let model: PolymarketOrderModel
    private weak var coordinator: PolymarketOrderRoutable?

    private var bag: Set<AnyCancellable> = []

    // MARK: - Init

    init(model: PolymarketOrderModel, coordinator: PolymarketOrderRoutable?) {
        self.model = model
        self.coordinator = coordinator

        marketRow = .make(market: model.market, outcome: model.outcome, eventTitle: model.eventTitle)
        fieldViewModel = model.amountField
        payment = Self.makePayment(balance: model.state.balance)
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
        case .closeTapped:
            coordinator?.closeOrder()
        case .nextTapped:
            coordinator?.openSummary(model: model)
        case .addFundsTapped:
            coordinator?.openAddFunds()
        case .slippageTapped:
            openSlippageSelector()
        case .fractionTapped(let fraction):
            model.handleViewAction(.fractionSelected(fraction))
        case .quoteRetryTapped:
            model.handleViewAction(.quoteRetried)
        }
    }
}

// MARK: - ViewAction

extension PolymarketOrderViewModel {
    enum ViewAction {
        case appeared
        case disappeared
        case closeTapped
        case nextTapped
        case addFundsTapped
        case slippageTapped
        case fractionTapped(PolymarketAmountFraction)
        case quoteRetryTapped
    }
}

// MARK: - Navigation

private extension PolymarketOrderViewModel {
    func openSlippageSelector() {
        coordinator?.openSlippageSelector(percent: model.state.slippagePercent) { [weak self] percent in
            self?.model.handleViewAction(.slippageSelected(percent))
        }
    }
}

// MARK: - Binding

private extension PolymarketOrderViewModel {
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

        payment = Self.makePayment(balance: state.balance)
        slippageText = PolymarketSlippageFormatter.rowText(state.slippagePercent)
        amountCaption = Self.makeAmountCaption(gate.amountCaption)
        amountFractions = Self.makeAmountFractions(balance: state.balance)
        notifications = gate.notifications
        isAwaitingFunds = state.isAwaitingFunds
        isNextEnabled = gate.isPrimaryButtonEnabled
    }
}

// MARK: - Mapping

private extension PolymarketOrderViewModel {
    static func makePayment(balance: Decimal?) -> PolymarketOrderPaymentRow.Model {
        .makeCollateral(balanceText: PolymarketOrderFormatter.money(balance))
    }

    static func makeAmountFractions(balance: Decimal?) -> [PolymarketAmountFraction] {
        guard let balance, balance > 0 else { return [] }

        return PolymarketAmountFraction.allCases
    }

    static func makeAmountCaption(_ caption: PolymarketOrderGate.AmountCaption?) -> AmountCaption? {
        switch caption {
        case .toWin(let expected, _):
            .toWin(PolymarketOrderFormatter.money(expected))
        case .belowMinAmount(let amount):
            .shortfall(Localization.predictionPlaceMinAmountError(PolymarketOrderFormatter.money(amount)))
        case .notEnoughForBet:
            .shortfall(Localization.predictionPlaceInsufficientBalanceBet)
        case .notEnoughForFees:
            .shortfall(Localization.predictionPlaceInsufficientBalanceFees)
        case nil:
            nil
        }
    }
}

// MARK: - Amount caption

extension PolymarketOrderViewModel {
    enum AmountCaption: Hashable {
        case toWin(String)
        case shortfall(String)
    }
}
