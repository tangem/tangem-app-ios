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

    @Published private(set) var payment: PolymarketOrderPaymentRow.Model?
    @Published private(set) var slippageText: String
    @Published private(set) var amountCaption: AmountCaption?
    @Published private(set) var amountFractions: [PolymarketAmountFraction] = []
    @Published private(set) var notifications: [PolymarketOrderNotification] = []
    @Published private(set) var isAwaitingFunds = false
    @Published private(set) var proceedsText = ""
    @Published private(set) var isProceedsStale = true
    @Published private(set) var sellingText: String?
    @Published private(set) var isNextEnabled = false

    var isProceedsLoading: Bool {
        proceedsText.isEmpty
    }

    // MARK: - Content

    @Published private(set) var marketRow: PolymarketOrderMarketRow.Model
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
        payment = Self.makePayment(balance: model.state.balance, intent: model.intent)
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
        case .stepTapped(let step):
            model.step(by: step)
        case .fractionTapped(let fraction):
            model.handleViewAction(.fractionSelected(fraction))
        }
    }
}

// MARK: - ViewAction

extension PolymarketOrderViewModel {
    var screenTitle: String {
        switch model.intent {
        case .buy: Localization.predictionPlaceTitle
        case .sell: Localization.predictionCloseTitle
        }
    }

    var amountTitle: String {
        switch model.intent {
        case .buy: Localization.predictionPlaceYouWillPay
        case .sell: Localization.predictionCloseYouWillReceive
        }
    }

    var nextButtonTitle: String {
        switch model.intent {
        case .buy: Localization.commonNext
        case .sell: Localization.predictionCloseButton
        }
    }

    var isAmountEditable: Bool {
        if case .buy = model.intent { true } else { false }
    }

    var isAddFundsAvailable: Bool {
        if case .buy = model.intent { true } else { false }
    }

    var showsBack: Bool {
        if case .sell = model.intent { true } else { false }
    }

    var amountPrefixSuffixOptions: SendDecimalNumberTextField.PrefixSuffixOptions {
        .prefix(text: AppConstants.usdSign, hasSpace: true)
    }

    enum ViewAction {
        case stepTapped(Int)
        case appeared
        case disappeared
        case closeTapped
        case nextTapped
        case addFundsTapped
        case slippageTapped
        case fractionTapped(PolymarketAmountFraction)
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
        let gate = PolymarketOrderGate(state: state, intent: model.intent)
        let isAwaitingQuote = state.enteredAmount != nil && state.quote.isAwaitingQuote

        payment = Self.makePayment(balance: state.balance, intent: model.intent)
        slippageText = PolymarketSlippageFormatter.rowText(state.slippagePercent)
        amountCaption = makeAmountCaption(gate.amountCaption) ?? (isAwaitingQuote ? amountCaption : nil)
        amountFractions = Self.makeAmountFractions(balance: state.balance)
        notifications = gate.notifications.isEmpty && isAwaitingQuote ? notifications : gate.notifications
        isAwaitingFunds = state.isAwaitingFunds
        isNextEnabled = gate.isPrimaryButtonEnabled

        if state.quote.isFailed || (state.bookPriceFailure != nil && state.quote.quote == nil) {
            marketRow = .make(
                market: model.market,
                outcome: model.outcome,
                eventTitle: model.eventTitle,
                isPriceUnavailable: true
            )
        } else if let price = state.quote.quote?.averagePrice ?? state.bookPrice {
            marketRow = .make(
                market: model.market,
                outcome: model.outcome,
                eventTitle: model.eventTitle,
                averagePrice: price
            )
        }

        if let quote = state.quote.quote {
            proceedsText = PolymarketOrderFormatter.money(quote.expectedExecutionAmount)
        } else if proceedsText.isEmpty, !isAwaitingQuote {
            proceedsText = .enDashSign
        }

        isProceedsStale = state.quote.quote == nil
        sellingText = Self.makeSellingText(state: state, intent: model.intent)

        if gate.notifications.contains(.marketClosed) {
            coordinator?.openMarketClosed()
        }

        switch state.bookPriceFailure {
        case .marketClosed: coordinator?.openMarketClosed()
        case .unreadable: coordinator?.openQuoteUnavailable()
        case nil: break
        }
    }
}

// MARK: - Mapping

private extension PolymarketOrderViewModel {
    static func makeSellingText(state: PolymarketOrderModel.State, intent: PolymarketOrderIntent) -> String? {
        guard case .sell(let held) = intent else { return nil }

        let selling = PolymarketOrderFormatter.shares(state.enteredAmount ?? 0)

        return Localization.predictionCloseSellingOf(selling, PolymarketOrderFormatter.shares(held))
    }

    static func makePayment(balance: Decimal?, intent: PolymarketOrderIntent) -> PolymarketOrderPaymentRow.Model? {
        switch intent {
        case .buy: .makeCollateral(balanceText: PolymarketOrderFormatter.money(balance))
        case .sell: nil
        }
    }

    static func makeAmountFractions(balance: Decimal?) -> [PolymarketAmountFraction] {
        guard let balance, balance > 0 else { return [] }

        return PolymarketAmountFraction.allCases
    }

    func minAmountText(_ amount: Decimal) -> String {
        switch model.intent {
        case .buy: Localization.predictionPlaceMinAmountError(PolymarketOrderFormatter.money(amount))
        case .sell: Localization.predictionCloseMinSharesError(PolymarketOrderFormatter.shares(amount))
        }
    }

    func makeAmountCaption(_ caption: PolymarketOrderGate.AmountCaption?) -> AmountCaption? {
        switch caption {
        case .toWin(let expected, _):
            .toWin(PolymarketOrderFormatter.money(expected))
        case .belowMinAmount(let amount):
            .shortfall(minAmountText(amount))
        case .notEnoughForBet:
            .shortfall(Localization.predictionPlaceInsufficientBalanceBet)
        case .notEnoughForFees:
            .shortfall(Localization.predictionPlaceInsufficientBalanceFees)
        // [REDACTED_TODO_COMMENT]
        case .notEnoughLiquidity:
            .shortfall("Not enough liquidity to sell this amount")
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
