//
//  PolymarketOrderModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import UIKit
import TangemFoundation
import TangemPolymarket

@MainActor
final class PolymarketOrderModel: ObservableObject {
    // MARK: - State

    @Published private(set) var state = State()

    // MARK: - Content

    let market: PolymarketMarket
    let outcome: PolymarketOutcome
    let eventTitle: String

    let intent: PolymarketOrderIntent
    let amountField: DecimalNumberTextFieldViewModel

    // MARK: - Dependencies

    private let apiProvider: PolymarketAPIProvider
    private let geoblockStateProvider: PolymarketGeoblockStateProvider
    private let positionsService: PolymarketPositionsService?
    private let clobService: PolymarketCLOBService
    private let isAwaitingFundsPublisher: AnyPublisher<Bool, Never>
    private let collateralBalancePublisher: AnyPublisher<Decimal?, Never>
    private let delayProvider: PollDelayProvider
    private let notificationCenter: NotificationCenter

    // MARK: - Private state

    private var quoteTask: Task<Void, Never>?
    private var heldSharesTask: Task<Decimal?, Never>?
    private var visibleScreens = 0
    private var bag: Set<AnyCancellable> = []

    // MARK: - Init

    init(
        market: PolymarketMarket,
        outcome: PolymarketOutcome,
        eventTitle: String,
        intent: PolymarketOrderIntent,
        apiProvider: PolymarketAPIProvider,
        geoblockStateProvider: PolymarketGeoblockStateProvider,
        positionsService: PolymarketPositionsService?,
        clobService: PolymarketCLOBService,
        isAwaitingFundsPublisher: AnyPublisher<Bool, Never>,
        collateralBalancePublisher: AnyPublisher<Decimal?, Never>,
        delayProvider: PollDelayProvider = TaskSleepPollDelayProvider(),
        notificationCenter: NotificationCenter = .default
    ) {
        self.market = market
        self.outcome = outcome
        self.eventTitle = eventTitle
        self.intent = intent
        self.apiProvider = apiProvider
        self.geoblockStateProvider = geoblockStateProvider
        self.positionsService = positionsService
        self.clobService = clobService
        self.isAwaitingFundsPublisher = isAwaitingFundsPublisher
        self.collateralBalancePublisher = collateralBalancePublisher
        self.delayProvider = delayProvider
        self.notificationCenter = notificationCenter

        amountField = DecimalNumberTextFieldViewModel(maximumFractionDigits: intent.fractionDigits)

        bind()
        readHeldShares()
    }

    deinit {
        quoteTask?.cancel()
        heldSharesTask?.cancel()
    }

    func awaitIndexing() -> PolymarketOrderIndexing {
        let positionsService = positionsService
        let conditionId = market.conditionId
        let heldSharesTask = heldSharesTask
        let assetId = outcome.assetId

        return Task {
            guard let positionsService, let conditionId else { return nil }

            var heldShares: Decimal?

            if let heldSharesTask {
                heldShares = await heldSharesTask.value
            }

            do {
                return try await positionsService.awaitPosition(
                    conditionId: conditionId,
                    assetId: assetId,
                    changedFrom: heldShares
                )
            } catch {
                guard !error.isCancellationError else { return nil }

                PolymarketLogger.error("Failed to wait for the position the order created", error: error)
                return nil
            }
        }
    }

    // MARK: - View actions

    func handleViewAction(_ action: ViewAction) {
        switch action {
        case .screenAppeared:
            visibleScreens += 1

            if visibleScreens == 1 {
                restartQuoteLoop(debounced: false)
            }
        case .screenDisappeared:
            visibleScreens = max(0, visibleScreens - 1)

            if visibleScreens == 0 {
                suspendQuoteLoop()
            }
        case .fractionSelected(let fraction):
            apply(fraction: fraction)
        case .slippageSelected(let percent):
            apply(slippagePercent: percent)
        }
    }
}

// MARK: - State

extension PolymarketOrderModel {
    func preselectWholePositionIfNeeded() {
        guard case .sell = intent, state.enteredAmount == nil, let balance = state.balance, balance > 0 else {
            return
        }

        select(amount: balance)
    }

    var entryPriceForVote: Decimal? {
        guard case .sell = intent else { return nil }

        return state.entryPrice
    }

    func step(by step: Int) {
        guard let balance = state.balance else { return }

        let floor = intent.floor(balance: balance)
        let current = state.enteredAmount ?? floor
        let capped = min(max(current + Decimal(step), floor), balance)
        let stepped = capped == balance
            ? balance
            : max(capped.rounded(scale: intent.fractionDigits, roundingMode: .down), floor)

        amountField.update(value: stepped)

        let quotable = stepped >= Constants.minQuotableAmount ? stepped : nil

        guard quotable != state.enteredAmount else { return }

        apply(enteredAmount: quotable, debounced: false)
    }

    func retryQuote() {
        restartQuoteLoop(debounced: false)
    }

    /// A quote answers one amount, so it has to stop counting the moment the amount changes. Both are moved in a
    /// single mutation, otherwise the old answer is published against the new amount for one pass and the gate
    /// reads it as a verdict on what the user has just typed.
    func apply(enteredAmount: Decimal?, debounced: Bool) {
        var updated = state
        updated.enteredAmount = enteredAmount
        updated.quote = .empty
        state = updated

        restartQuoteLoop(debounced: debounced)
    }

    struct State: Equatable {
        var quote: PolymarketOrderQuoteState = .empty
        var quoteReceivedAt: Date?
        var enteredAmount: Decimal?
        var minAmount: Decimal?
        var balance: Decimal?
        var collateralBalance: Decimal?
        var entryPrice: Decimal?
        var slippagePercent: Decimal = PolymarketSlippage.defaultPercent
        var geoblock: PolymarketGeoblockState = .unknown
        var isAwaitingFunds = false
        var bookPrice: Decimal?
        var bookPriceFailure: PolymarketBookPriceFailure?
        var isBookPriceResuming = false

        var isBelowMinAmount: Bool {
            guard let enteredAmount, let minAmount else { return false }

            return enteredAmount < minAmount
        }
    }
}

// MARK: - ViewAction

extension PolymarketOrderModel {
    enum ViewAction {
        case screenAppeared
        case screenDisappeared
        case fractionSelected(PolymarketAmountFraction)
        case slippageSelected(Decimal)
    }
}

// MARK: - Binding

private extension PolymarketOrderModel {
    func bind() {
        amountField
            .valuePublisher()
            .map { value in
                value.flatMap { $0 >= Constants.minQuotableAmount ? $0 : nil }
            }
            .removeDuplicates()
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { model, amount in
                model.apply(enteredAmount: amount, debounced: true)
            }

            .store(in: &bag)

        collateralBalancePublisher
            .removeDuplicates()
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { model, balance in
                model.state.collateralBalance = balance
            }
            .store(in: &bag)

        intent.availablePublisher
            .removeDuplicates()
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { model, balance in
                model.state.balance = balance
                model.preselectWholePositionIfNeeded()
            }
            .store(in: &bag)

        isAwaitingFundsPublisher
            .dropFirst()
            .removeDuplicates()
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { model, isAwaitingFunds in
                model.state.isAwaitingFunds = isAwaitingFunds
            }
            .store(in: &bag)

        geoblockStateProvider
            .statePublisher
            .removeDuplicates()
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { model, geoblock in
                model.state.geoblock = geoblock
            }
            .store(in: &bag)

        notificationCenter
            .publisher(for: UIApplication.didEnterBackgroundNotification)
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { model, _ in
                model.suspendQuoteLoop()
            }
            .store(in: &bag)

        notificationCenter
            .publisher(for: UIApplication.willEnterForegroundNotification)
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { model, _ in
                guard model.visibleScreens > 0 else { return }

                model.restartQuoteLoop(debounced: false, resuming: true)
            }
            .store(in: &bag)
    }
}

// MARK: - Actions

private extension PolymarketOrderModel {
    func apply(slippagePercent: Decimal) {
        guard slippagePercent != state.slippagePercent else { return }

        state.slippagePercent = slippagePercent
        restartQuoteLoop(debounced: false)
    }

    func apply(fraction: PolymarketAmountFraction) {
        guard let balance = state.balance, balance > 0 else { return }

        select(amount: spendable(fraction: fraction, of: balance))
    }

    func select(amount: Decimal) {
        amountField.update(value: amount)

        let quotable = amount >= Constants.minQuotableAmount ? amount : nil

        guard quotable != state.enteredAmount else { return }

        apply(enteredAmount: quotable, debounced: false)
    }

    func spendable(fraction: PolymarketAmountFraction, of balance: Decimal) -> Decimal {
        guard fraction == .max else {
            let share = (balance * fraction.multiplier).rounded(scale: intent.stepFractionDigits, roundingMode: .down)

            guard case .sell = intent else { return share }

            return max(share, intent.floor(balance: balance))
        }

        if intent.maxOffersWholePosition {
            return balance
        }

        let share = balance * Constants.maxShareOfBalance
        let feeCeiling = balance / (1 + feeRate)

        return min(share, feeCeiling).rounded(scale: intent.fractionDigits, roundingMode: .down)
    }

    var feeRate: Decimal {
        guard let quote = state.quote.quote, quote.notional > 0 else { return 0 }

        return quote.fees.total / quote.notional
    }
}

// MARK: - The position the order changes

private extension PolymarketOrderModel {
    func readHeldShares() {
        guard let positionsService, let conditionId = market.conditionId else { return }

        let assetId = outcome.assetId

        heldSharesTask = Task { [weak self] in
            do {
                let position = try await Self.heldPosition(
                    service: positionsService,
                    conditionId: conditionId,
                    assetId: assetId
                )

                self?.state.entryPrice = position?.avgPrice
                self?.applyHeldShares(position?.size)

                return position?.size
            } catch {
                guard !error.isCancellationError else { return nil }

                PolymarketLogger.error("Failed to read the position the order will change", error: error)
                return nil
            }
        }
    }

    func applyHeldShares(_ size: Decimal?) {
        guard case .sell = intent, let size, size != state.balance else { return }

        let heldWholePosition = state.enteredAmount == state.balance

        state.balance = size

        guard heldWholePosition || (state.enteredAmount ?? 0) > size else {
            preselectWholePositionIfNeeded()
            return
        }

        select(amount: size)
    }

    static func heldPosition(
        service: PolymarketPositionsService,
        conditionId: String,
        assetId: String
    ) async throws -> PolymarketPosition? {
        do {
            return try await service.position(conditionId: conditionId, assetId: assetId)
        } catch {
            guard (error as? PolymarketAPIError)?.isTransient == true else { throw error }

            return try await service.position(conditionId: conditionId, assetId: assetId)
        }
    }
}

// MARK: - Quote loop

private extension PolymarketOrderModel {
    func restartQuoteLoop(debounced: Bool, resuming: Bool = false) {
        quoteTask?.cancel()

        var updated = state
        updated.quote = resuming && state.enteredAmount != nil
            ? .resuming(hiddenFailuresLeft: Constants.hiddenTransientFailuresOnResume)
            : .empty
        updated.isBookPriceResuming = resuming && state.enteredAmount == nil
        state = updated

        guard visibleScreens > 0 else {
            quoteTask = nil
            return
        }

        guard state.enteredAmount != nil else {
            quoteTask = runTask(in: self) { [delayProvider] model in
                let polling = PollingSequence(
                    interval: Constants.pollInterval,
                    request: { await model.requestBookPrice() },
                    delayProvider: delayProvider
                )

                for await _ in polling {}
            }
            return
        }

        quoteTask = runTask(in: self) { [delayProvider] model in
            if debounced {
                try? await delayProvider.wait(for: Constants.debounce)
            }

            let polling = PollingSequence(
                interval: { model.pollInterval },
                request: { await model.requestQuote() },
                delayProvider: delayProvider
            )

            for await _ in polling {}
        }
    }

    func suspendQuoteLoop() {
        quoteTask?.cancel()
        quoteTask = nil
    }

    var pollInterval: TimeInterval {
        Constants.pollInterval
    }

    func requestBookPrice() async {
        do {
            let price = try await clobService.price(tokenId: outcome.assetId, side: intent.side)

            guard !Task.isCancelled else { return }

            var updated = state
            updated.bookPrice = price
            updated.bookPriceFailure = nil
            updated.isBookPriceResuming = false
            state = updated
        } catch {
            guard !Task.isCancelled, !error.isCancellationError else { return }

            PolymarketLogger.error("Order book price request failed", error: error)

            guard let failure = PolymarketBookPriceFailure(error: error) else { return }

            var updated = state
            updated.bookPriceFailure = failure
            updated.isBookPriceResuming = false
            state = updated
            suspendQuoteLoop()
        }
    }

    func requestQuote() async {
        guard let amount = state.enteredAmount else { return }

        if case .empty = state.quote {
            state.quote = .loading
        }

        let request = PolymarketOrderQuoteRequest(
            marketId: market.id,
            assetId: outcome.assetId,
            side: intent.side,
            amount: amount,
            slippagePercent: state.slippagePercent
        )

        do {
            let quote = try await apiProvider.orderQuote(request: request)
            guard !Task.isCancelled else { return }

            var updated = state
            updated.minAmount = intent.minAmount(from: quote)
            updated.quote = PolymarketOrderQuoteState(quote: quote)
            updated.quoteReceivedAt = Date()
            state = updated

            if quote.status == .marketClosed {
                suspendQuoteLoop()
            }
        } catch {
            guard !Task.isCancelled, !error.isCancellationError else { return }

            PolymarketLogger.error("Order quote request failed", error: error)
            handleQuoteFailure(error)
        }
    }

    func handleQuoteFailure(_ error: Error) {
        if case .resuming(let hiddenFailuresLeft) = state.quote,
           hiddenFailuresLeft > 0,
           (error as? PolymarketAPIError)?.isTransient == true {
            state.quote = .resuming(hiddenFailuresLeft: hiddenFailuresLeft - 1)
            return
        }

        state.quote = .failed(PolymarketOrderQuoteFailure(error: error))
    }
}

extension PolymarketOrderModel {
    nonisolated static let maxQuoteAge: TimeInterval = 30
}

extension PolymarketOrderModel.State {
    func keepsQuote(at moment: Date) -> Bool {
        guard quote.quote != nil, let quoteReceivedAt else { return false }

        return moment.timeIntervalSince(quoteReceivedAt) <= PolymarketOrderModel.maxQuoteAge
    }
}

// MARK: - Constants

private extension PolymarketOrderModel {
    enum Constants {
        static let minQuotableAmount: Decimal = 0.01
        static let maxShareOfBalance: Decimal = 0.9
        static let debounce: TimeInterval = 0.5
        static let pollInterval: TimeInterval = 3
        static let hiddenTransientFailuresOnResume = 1
    }
}
