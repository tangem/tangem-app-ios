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
    @Published private(set) var amountFractions: [FractionOption] = []
    @Published private(set) var notifications: [PolymarketOrderNotification] = []
    @Published private(set) var isAwaitingFunds = false
    @Published private(set) var proceedsText = ""
    @Published private(set) var isProceedsStale = true
    @Published private(set) var sellingText: String?
    @Published private(set) var isNextEnabled = false
    @Published private(set) var canDecreaseAmount = false
    @Published private(set) var canIncreaseAmount = false
    @Published private(set) var areFractionsEnabled = false

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

        marketRow = .make(
            market: model.market,
            outcome: model.outcome,
            eventTitle: model.eventTitle,
            entryPrice: model.entryPriceForVote
        )
        fieldViewModel = model.amountField
        payment = Self.makePayment(balance: model.state.balance, intent: model.intent)
        slippageText = PolymarketSlippageFormatter.rowText(model.state.slippagePercent)

        bind()
    }

    // MARK: - View actions

    func handleViewAction(_ action: ViewAction) {
        switch action {
        case .onAppear:
            model.handleViewAction(.onAppear)
        case .onDisappear:
            model.handleViewAction(.onDisappear)
        case .close:
            coordinator?.closeOrder()
        case .openSummary:
            coordinator?.openSummary(model: model)
        case .openAddFunds:
            coordinator?.openAddFunds()
        case .openSlippage:
            openSlippageSelector()
        case .step(let step):
            model.handleViewAction(.step(step))
        case .selectFraction(let fraction):
            model.handleViewAction(.selectFraction(fraction))
        case .retryQuote:
            model.handleViewAction(.retryQuote)
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

    struct FractionOption: Identifiable, Hashable {
        let fraction: PolymarketAmountFraction
        let isEnabled: Bool

        var id: PolymarketAmountFraction { fraction }
    }

    enum ViewAction {
        case step(Int)
        case onAppear
        case onDisappear
        case close
        case openSummary
        case openAddFunds
        case openSlippage
        case selectFraction(PolymarketAmountFraction)
        case retryQuote
    }
}

// MARK: - Navigation

private extension PolymarketOrderViewModel {
    func openSlippageSelector() {
        coordinator?.openSlippageSelector(percent: model.state.slippagePercent) { [weak self] percent in
            self?.model.handleViewAction(.selectSlippage(percent))
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
        let keepsPreviousHints = state.enteredAmount != nil && state.quote.isAwaitingQuote && !state.quote.isResuming

        payment = Self.makePayment(balance: state.balance, intent: model.intent)
        slippageText = PolymarketSlippageFormatter.rowText(state.slippagePercent)
        amountCaption = makeAmountCaption(gate.amountCaption) ?? (keepsPreviousHints ? amountCaption : nil)
        amountFractions = Self.makeAmountFractions(balance: state.balance, selectable: gate.selectableFractions)
        notifications = gate.notifications.isEmpty && keepsPreviousHints ? notifications : gate.notifications
        isAwaitingFunds = state.isAwaitingFunds
        isNextEnabled = gate.isPrimaryButtonEnabled

        let isTradable = model.market.isAcceptingOrders && !gate.notifications.contains(.marketClosed)

        let isAdjustable = isTradable && (gate.canStepUp || gate.canStepDown)

        areFractionsEnabled = isAdjustable
        canDecreaseAmount = isAdjustable && gate.canStepDown
        canIncreaseAmount = isAdjustable && gate.canStepUp

        if state.quote.isResuming || state.isBookPriceResuming {
            marketRow = marketRow.settling(nextPriceText: nil, isLoading: true)
        } else if state.quote.isFailed || (state.bookPriceFailure != nil && state.quote.quote == nil) {
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
                averagePrice: price,
                entryPrice: model.entryPriceForVote
            )
        } else if marketRow.isOutcomeNextPriceLoading {
            marketRow = marketRow.settling(nextPriceText: nil, isLoading: false)
        }

        if state.quote.isResuming {
            proceedsText = ""
        } else if let expectedExecutionAmount = state.quote.expectedExecutionAmount {
            proceedsText = PolymarketOrderFormatter.money(expectedExecutionAmount)
        } else if state.enteredAmount != nil, !state.quote.isAwaitingQuote {
            proceedsText = .enDashSign
        }

        isProceedsStale = state.quote.expectedExecutionAmount == nil
        sellingText = Self.makeSellingText(state: state, intent: model.intent)

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
        let total = PolymarketOrderFormatter.shares(state.balance ?? held)

        return Localization.predictionCloseSellingOf(selling, total)
    }

    static func makePayment(balance: Decimal?, intent: PolymarketOrderIntent) -> PolymarketOrderPaymentRow.Model? {
        switch intent {
        case .buy: .makeCollateral(balanceText: PolymarketOrderFormatter.money(balance))
        case .sell: nil
        }
    }

    static func makeAmountFractions(
        balance: Decimal?,
        selectable: Set<PolymarketAmountFraction>
    ) -> [FractionOption] {
        guard let balance, balance > 0 else { return [] }

        return PolymarketAmountFraction.allCases.map {
            FractionOption(fraction: $0, isEnabled: selectable.contains($0))
        }
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
