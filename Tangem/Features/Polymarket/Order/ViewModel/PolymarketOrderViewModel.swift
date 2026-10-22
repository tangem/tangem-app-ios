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
import TangemUI
import TangemUIUtils

@MainActor
final class PolymarketOrderViewModel: ObservableObject {
    // MARK: - View state

    @Published private(set) var payment: PolymarketOrderPaymentRow.Model?
    @Published private(set) var slippageText: String
    @Published private(set) var amountCaption: AmountCaption?
    @Published private(set) var amountFractions: [FractionOption] = []
    @Published private(set) var amountPresets: [AmountPreset] = []
    @Published private(set) var notifications: [PolymarketOrderNotification] = []
    @Published private(set) var isAwaitingFunds = false
    @Published private(set) var proceedsText = ""
    @Published private(set) var isProceedsStale = true
    @Published private(set) var sellingText: String?
    @Published private(set) var isNextEnabled = false
    @Published private(set) var canDecreaseAmount = false
    @Published private(set) var canIncreaseAmount = false
    @Published private(set) var areFractionsEnabled = false
    @Published private(set) var isAddFundsEnabled = false
    @Published private(set) var showsTotal = false
    @Published private(set) var totalText = ""
    @Published private(set) var isTotalLoading = false
    @Published private(set) var isFeeBreakdownAvailable = false
    @Published private(set) var isPlacing = false
    @Published var alert: AlertBinder?

    var isProceedsLoading: Bool {
        proceedsText.isEmpty
    }

    // MARK: - Content

    @Published private(set) var marketRow: PolymarketOrderMarketRow.Model
    let fieldViewModel: DecimalNumberTextFieldViewModel
    let flowStyle: PolymarketOrderFlowStyle

    // MARK: - Dependencies

    private let model: PolymarketOrderModel
    private let submission: PolymarketOrderSubmission?
    private weak var coordinator: PolymarketOrderRoutable?

    private var placementTask: Task<Void, Never>?
    private var hintsAmount: Decimal?
    private var pendingPlacementDate: Date?
    private let now: () -> Date
    private var bag: Set<AnyCancellable> = []

    // MARK: - Init

    init(
        model: PolymarketOrderModel,
        flowStyle: PolymarketOrderFlowStyle = .summaryStep,
        coordinator: PolymarketOrderRoutable?,
        now: @escaping () -> Date = Date.init
    ) {
        self.model = model
        self.flowStyle = flowStyle
        self.coordinator = coordinator
        self.now = now
        submission = flowStyle.singleSheet.map { PolymarketOrderSubmission(model: model, placementService: $0.placementService) }

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

    deinit {
        placementTask?.cancel()
    }

    // MARK: - View actions

    func handleViewAction(_ action: ViewAction) {
        switch action {
        case .onAppear:
            model.handleViewAction(.onAppear)
        case .onDisappear:
            dropPendingPlacement()
            model.handleViewAction(.onDisappear)
        case .close:
            guard !isPlacing else { return }

            coordinator?.closeOrder()
        case .openSummary:
            coordinator?.openSummary(model: model)
        case .placeOrder:
            place()
        case .openFeeBreakdown:
            guard isFeeBreakdownAvailable else { return }

            coordinator?.openFeeBreakdown(model: model)
        case .openLegalTerms(let url):
            coordinator?.openLegalTerms(url: url)
        case .openAddFunds:
            openAddFunds()
        case .openSlippage:
            openSlippageSelector()
        case .step(let step):
            model.handleViewAction(.step(step))
        case .selectFraction(let fraction):
            model.handleViewAction(.selectFraction(fraction))
        case .selectPreset(let preset):
            switch preset {
            case .amount(let amount): model.handleViewAction(.selectAmount(amount))
            case .max: model.handleViewAction(.selectFraction(.max))
            }
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

    var isSingleSheet: Bool {
        flowStyle.isSingleSheet
    }

    var nextButtonTitle: String {
        switch model.intent {
        case .buy: isSingleSheet ? Localization.predictionPlaceButton : Localization.commonNext
        case .sell: Localization.predictionCloseButton
        }
    }

    var isAmountEditable: Bool {
        if case .buy = model.intent { true } else { false }
    }

    var amountPrefixSuffixOptions: SendDecimalNumberTextField.PrefixSuffixOptions {
        .prefix(text: AppConstants.usdSign, hasSpace: false)
    }

    struct FractionOption: Identifiable, Hashable {
        let fraction: PolymarketAmountFraction
        let isEnabled: Bool

        var id: PolymarketAmountFraction { fraction }
    }

    struct AmountPreset: Identifiable, Hashable {
        enum Kind: Hashable {
            case amount(Decimal)
            case max
        }

        let kind: Kind
        let title: String
        let isEnabled: Bool

        var id: Kind { kind }
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
        case selectPreset(AmountPreset.Kind)
        case retryQuote
        case placeOrder
        case openFeeBreakdown
        case openLegalTerms(URL)
    }
}

// MARK: - Navigation

private extension PolymarketOrderViewModel {
    func openAddFunds() {
        guard !model.state.geoblock.isBlocked else {
            coordinator?.openRegionWarning()
            return
        }

        switch model.state.addFundsReadiness.addFundsAvailability {
        case .available:
            coordinator?.openAddFunds()
        case .loading:
            break
        case .unavailable:
            showAddFundsUnavailableAlert()
        }
    }

    func showAddFundsUnavailableAlert() {
        alert = AlertBuilder.makeOkGotItAlert(message: Localization.predictionAddFundsErrorDescription)
    }

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
        let isAwaitingFreshQuote = state.enteredAmount != nil && state.quote.isAwaitingQuote && !state.quote.isResuming
        let keepsPreviousHints = isAwaitingFreshQuote && (!isSingleSheet || state.enteredAmount == hintsAmount)

        payment = Self.makePayment(balance: state.balance, intent: model.intent)
        slippageText = PolymarketSlippageFormatter.rowText(state.slippagePercent)
        amountCaption = makeAmountCaption(gate.amountCaption) ?? previousOrPendingCaption(
            keepsPreviousHints: keepsPreviousHints,
            isAwaitingFreshQuote: isAwaitingFreshQuote
        )
        amountFractions = Self.makeAmountFractions(balance: state.balance, selectable: gate.selectableFractions)
        notifications = gate.notifications.isEmpty && keepsPreviousHints ? notifications : gate.notifications

        if !state.quote.isAwaitingQuote {
            hintsAmount = state.enteredAmount
        }
        isAwaitingFunds = state.isAwaitingFunds
        isAddFundsEnabled = state.addFundsReadiness.addFundsAvailability == .available
        isNextEnabled = gate.isPrimaryButtonEnabled || (isSingleSheet && isAwaitingFreshQuote && gate.isPrimaryButtonEnabledWhileQuoting)

        if isSingleSheet {
            updateTotal(with: state)
            placeOnceQuoted(state: state, gate: gate)
        }

        let isTradable = model.market.isAcceptingOrders && !gate.notifications.contains(.marketClosed)

        let isAdjustable = isTradable && (gate.canStepUp || gate.canStepDown)

        areFractionsEnabled = isAdjustable
        amountPresets = makeAmountPresets(isTradable: isTradable)
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

// MARK: - Single sheet

private extension PolymarketOrderViewModel {
    func updateTotal(with state: PolymarketOrderModel.State) {
        let quote = state.quote.quote ?? state.quote.partialQuote

        showsTotal = state.enteredAmount != nil
        totalText = PolymarketOrderFormatter.money(quote?.total)
        isTotalLoading = showsTotal && quote == nil && state.quote.isAwaitingQuote
        isFeeBreakdownAvailable = quote != nil
    }

    func place() {
        guard let submission, !isPlacing, isNextEnabled else { return }

        isPlacing = true
        placeIfReady(submission, waitsForQuote: true)
    }

    func placeOnceQuoted(state: PolymarketOrderModel.State, gate: PolymarketOrderGate) {
        guard let tapDate = pendingPlacementDate, !state.quote.isAwaitingQuote else { return }

        pendingPlacementDate = nil

        guard now().timeIntervalSince(tapDate) <= Constants.pendingPlacementLifetime else {
            isPlacing = false
            return
        }

        guard let submission, gate.isPrimaryButtonEnabled else {
            isPlacing = false
            return
        }

        placeIfReady(submission, waitsForQuote: false)
    }

    func dropPendingPlacement() {
        guard pendingPlacementDate != nil else { return }

        pendingPlacementDate = nil
        isPlacing = false
    }

    func placeIfReady(_ submission: PolymarketOrderSubmission, waitsForQuote: Bool) {
        switch submission.readiness() {
        case .ready(let quote):
            placementTask = Task { @MainActor [weak self] in
                guard let self else { return }

                handle(await submission.submit(quote: quote) { self.marketRow })
            }
        case .unavailable where waitsForQuote:
            pendingPlacementDate = now()
        case .unavailable:
            isPlacing = false
        case .staleQuote:
            isPlacing = false
            alert = PolymarketOrderSubmission.staleQuoteAlert(onAcknowledge: {})
        }
    }

    func handle(_ outcome: PolymarketOrderSubmission.Outcome) {
        switch outcome {
        case .cancelled:
            isPlacing = false
        case .failed(let returningToMain):
            if !returningToMain {
                isPlacing = false
            }

            alert = PolymarketOrderSubmission.failureAlert(
                returningToMain: returningToMain,
                onSupport: { [weak self] in self?.coordinator?.openSupport() },
                onClose: { [weak self] in self?.coordinator?.closeOrder() }
            )
        case .finished(let state, let content):
            isPlacing = false
            coordinator?.openResult(state: state, content: content)
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

    func makeAmountPresets(isTradable: Bool) -> [AmountPreset] {
        guard isSingleSheet, isAmountEditable else { return [] }

        let amounts = Constants.amountPresets.map {
            AmountPreset(kind: .amount($0), title: PolymarketOrderFormatter.enteredAmount($0), isEnabled: isTradable)
        }

        let isMaxEnabled = isTradable && amountFractions.contains { $0.fraction == .max && $0.isEnabled }
        let max = AmountPreset(kind: .max, title: Localization.sendMaxAmount, isEnabled: isMaxEnabled)

        return amounts + [max]
    }

    func minAmountText(_ amount: Decimal) -> String {
        switch model.intent {
        case .buy: Localization.predictionPlaceMinAmountError(PolymarketOrderFormatter.money(amount))
        case .sell: Localization.predictionCloseMinSharesError(PolymarketOrderFormatter.shares(amount))
        }
    }

    func previousOrPendingCaption(keepsPreviousHints: Bool, isAwaitingFreshQuote: Bool) -> AmountCaption? {
        if keepsPreviousHints {
            return amountCaption
        }

        guard isSingleSheet, isAmountEditable, isAwaitingFreshQuote else { return nil }

        switch amountCaption {
        case .toWin(let text): return .toWinLoading(text)
        case .toWinLoading(let text): return .toWinLoading(text)
        case .shortfall, nil: return .toWinLoading(nil)
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
        case toWinLoading(String?)
        case shortfall(String)
    }
}

// MARK: - Constants

private extension PolymarketOrderViewModel {
    enum Constants {
        static let amountPresets: [Decimal] = [100, 500, 1000, 5000]
        static let pendingPlacementLifetime: TimeInterval = 10
    }
}
