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
    private let isAwaitingFundsPublisher: AnyPublisher<Bool, Never>
    private let delayProvider: PollDelayProvider

    // MARK: - Private state

    private var quoteTask: Task<Void, Never>?
    private var heldSharesTask: Task<Decimal?, Never>?
    private var visibleScreens = 0
    private var failureClock = PolymarketQuoteFailureClock(gracePeriod: Constants.failureGracePeriod)
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
        isAwaitingFundsPublisher: AnyPublisher<Bool, Never>,
        delayProvider: PollDelayProvider = TaskSleepPollDelayProvider()
    ) {
        self.market = market
        self.outcome = outcome
        self.eventTitle = eventTitle
        self.intent = intent
        self.apiProvider = apiProvider
        self.geoblockStateProvider = geoblockStateProvider
        self.positionsService = positionsService
        self.isAwaitingFundsPublisher = isAwaitingFundsPublisher
        self.delayProvider = delayProvider

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
        case .quoteRetried:
            restartQuoteLoop(debounced: false)
        }
    }
}

// MARK: - State

extension PolymarketOrderModel {
    func preselectWholePositionIfNeeded() {
        guard case .sell = intent, state.enteredAmount == nil, let balance = state.balance, balance > 0 else {
            return
        }

        apply(fraction: .max)
    }

    func step(by step: Int) {
        guard let balance = state.balance else { return }

        let current = state.enteredAmount ?? 0
        let capped = min(max(current + Decimal(step), 0), balance)
        let stepped = capped == balance
            ? balance
            : capped.rounded(scale: intent.fractionDigits, roundingMode: .down)

        amountField.update(value: stepped)

        let quotable = stepped >= Constants.minQuotableAmount ? stepped : nil

        guard quotable != state.enteredAmount else { return }

        state.enteredAmount = quotable
        restartQuoteLoop(debounced: false)
    }

    struct State: Equatable {
        var quote: PolymarketOrderQuoteState = .empty
        var quoteReceivedAt: Date?
        var enteredAmount: Decimal?
        var minAmount: Decimal?
        var balance: Decimal?
        var slippagePercent: Decimal = PolymarketSlippage.defaultPercent
        var geoblock: PolymarketGeoblockState = .unknown
        var isAwaitingFunds = false

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
        case quoteRetried
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
                model.state.enteredAmount = amount
                model.restartQuoteLoop(debounced: true)
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

        NotificationCenter.default
            .publisher(for: UIApplication.didEnterBackgroundNotification)
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { model, _ in
                model.suspendQuoteLoop()
            }
            .store(in: &bag)

        NotificationCenter.default
            .publisher(for: UIApplication.willEnterForegroundNotification)
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { model, _ in
                guard model.visibleScreens > 0 else { return }

                model.restartQuoteLoop(debounced: false)
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

        let amount = spendable(fraction: fraction, of: balance)

        amountField.update(value: amount)

        let quotable = amount >= Constants.minQuotableAmount ? amount : nil

        guard quotable != state.enteredAmount else { return }

        state.enteredAmount = quotable
        restartQuoteLoop(debounced: false)
    }

    func spendable(fraction: PolymarketAmountFraction, of balance: Decimal) -> Decimal {
        guard fraction == .max else {
            return (balance * fraction.multiplier).rounded(scale: intent.fractionDigits, roundingMode: .down)
        }

        guard intent.deductsFeeFromMax else {
            return balance
        }

        return (balance / (1 + feeRate)).rounded(scale: intent.fractionDigits, roundingMode: .down)
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
                let size = try await Self.heldPosition(
                    service: positionsService,
                    conditionId: conditionId,
                    assetId: assetId
                )?.size

                self?.applyHeldShares(size)

                return size
            } catch {
                guard !error.isCancellationError else { return nil }

                PolymarketLogger.error("Failed to read the position the order will change", error: error)
                return nil
            }
        }
    }

    func applyHeldShares(_ size: Decimal?) {
        guard case .sell = intent, let size, size != state.balance else { return }

        state.balance = size
        preselectWholePositionIfNeeded()
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
    func restartQuoteLoop(debounced: Bool) {
        quoteTask?.cancel()
        state.quote = .empty

        guard visibleScreens > 0, state.enteredAmount != nil, !state.isBelowMinAmount else {
            quoteTask = nil
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
        failureClock.reset()
    }

    var pollInterval: TimeInterval {
        state.quote.isLive ? Constants.livePollInterval : Constants.pollInterval
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

            failureClock.reset()
            state.minAmount = intent.minAmount(from: quote)
            state.quote = PolymarketOrderQuoteState(quote: quote)
            state.quoteReceivedAt = Date()

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
        guard failureClock.shouldSurfaceFailure(hasQuote: state.quote.quote != nil) else { return }

        state.quote = .failed(PolymarketOrderQuoteFailure(error: error))
    }
}

// MARK: - Constants

private extension PolymarketOrderModel {
    enum Constants {
        static let minQuotableAmount: Decimal = 0.01
        static let debounce: TimeInterval = 0.5
        static let livePollInterval: TimeInterval = 3
        static let pollInterval: TimeInterval = 15
        static let failureGracePeriod: TimeInterval = 30
    }
}
