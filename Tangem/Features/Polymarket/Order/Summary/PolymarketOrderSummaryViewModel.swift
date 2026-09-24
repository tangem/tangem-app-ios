//
//  PolymarketOrderSummaryViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import SwiftUI
import TangemFoundation
import TangemLocalization
import TangemPolymarket
import TangemPolymarketUI
import TangemUIUtils

@MainActor
final class PolymarketOrderSummaryViewModel: ObservableObject {
    // MARK: - View state

    @Published private(set) var header: PolymarketOrderSummaryHeader.Model
    @Published private(set) var feeText: String
    @Published private(set) var slippageText: String
    @Published private(set) var notifications: [PolymarketOrderNotification] = []
    @Published private(set) var isPlaceEnabled = false
    @Published private(set) var isFeeBreakdownAvailable = false
    @Published private(set) var isPlacing = false
    @Published var alert: AlertBinder?

    // MARK: - Content

    @Published private(set) var marketRow: PolymarketOrderMarketRow.Model
    let currencyCode = PolymarketUtilities.collateralTokenItem.currencySymbol

    // MARK: - Dependencies

    private let model: PolymarketOrderModel
    private let account: PolymarketOrderAccount?
    private let placementService: PolymarketOrderPlacementService
    private weak var coordinator: PolymarketOrderSummaryRoutable?

    private var placementTask: Task<Void, Never>?
    private var bag: Set<AnyCancellable> = []

    // MARK: - Init

    init(
        model: PolymarketOrderModel,
        account: PolymarketOrderAccount?,
        placementService: PolymarketOrderPlacementService,
        coordinator: PolymarketOrderSummaryRoutable?
    ) {
        self.model = model
        self.account = account
        self.placementService = placementService
        self.coordinator = coordinator

        marketRow = .make(market: model.market, outcome: model.outcome, eventTitle: model.eventTitle)
        header = Self.makeHeader(state: model.state, intent: model.intent, account: account)
        feeText = Self.makeFeeText(state: model.state)
        slippageText = PolymarketSlippageFormatter.rowText(model.state.slippagePercent)

        bind()
    }

    deinit {
        placementTask?.cancel()
    }

    // MARK: - View actions

    func handleViewAction(_ action: ViewAction) {
        switch action {
        case .appeared, .disappeared:
            break
        case .backTapped:
            guard !isPlacing else { return }

            coordinator?.closeSummary()
        case .closeTapped:
            guard !isPlacing else { return }

            coordinator?.closeOrder()
        case .placeTapped:
            place()
        case .feeTapped:
            openFeeBreakdown()
        case .legalTermsTapped(let url):
            coordinator?.openLegalTerms(url: url)
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
    }
}

// MARK: - Placement

private extension PolymarketOrderSummaryViewModel {
    func place() {
        guard !isPlacing, let quote = model.state.quote.quote else { return }

        guard let receivedAt = model.state.quoteReceivedAt,
              Date().timeIntervalSince(receivedAt) <= Constants.maxQuoteAge else {
            reportStaleQuote()
            return
        }

        isPlacing = true

        placementTask = Task { @MainActor [weak self] in
            guard let self else { return }

            do {
                let placement = try await placementService.place(
                    quote: quote,
                    market: model.market,
                    outcome: model.outcome
                )

                guard !placement.isMatchedWithoutFill else {
                    PolymarketLogger.error(
                        "The exchange matched the order and filled no shares",
                        error: PlacementAnomaly.matchedWithoutFill
                    )
                    reportFailure()
                    return
                }

                finish(
                    with: .init(placement: placement, quotedShares: quote.shares, side: model.intent.side),
                    placement: placement,
                    quote: quote
                )
            } catch let error as PolymarketOrderPlacementError {
                handle(error, quote: quote)
            } catch is CancellationError {
                resume()
            } catch {
                PolymarketLogger.error("Order placement failed", error: error)
                reportFailure()
            }
        }
    }

    func handle(_ error: PolymarketOrderPlacementError, quote: PolymarketOrderQuote) {
        switch error {
        case .noLiquidity:
            PolymarketLogger.error("The book had nothing to match the order", error: error)
            finish(with: .noFill, placement: nil, quote: quote)
        case _ where error.isAmbiguous:
            PolymarketLogger.error("The order was sent and its outcome is unknown", error: error)
            finish(with: .stillProcessing, placement: nil, quote: quote)
        case _ where error.isUserCancellation:
            resume()
        default:
            PolymarketLogger.error("Order placement failed", error: error)
            reportFailure()
        }
    }

    func reportFailure() {
        resume()
        alert = AlertBuilder.makeAlert(
            title: Localization.commonSomethingWentWrong,
            message: Localization.predictionPlaceErrorDescription,
            primaryButton: .default(Text(Localization.commonSupport)) { [weak self] in
                self?.coordinator?.openSupport()
            },
            secondaryButton: .cancel(Text(Localization.commonClose))
        )
    }

    func reportStaleQuote() {
        resume()
        alert = AlertBuilder.makeOkGotItAlert(
            message: Localization.predictionPlacePriceChangedDescription,
            okAction: { [weak self] in self?.coordinator?.closeSummary() }
        )
    }

    func resume() {
        isPlacing = false
    }

    @MainActor
    func finish(
        with state: PolymarketOrderResultViewModel.State,
        placement: PolymarketOrderPlacement?,
        quote: PolymarketOrderQuote?
    ) {
        isPlacing = false
        coordinator?.openResult(state: state, content: makeResultContent(placement: placement, quote: quote))
    }

    func filledMoney(_ placement: PolymarketOrderPlacement?) -> Decimal? {
        switch model.intent.side {
        case .buy: placement?.makingAmount
        case .sell: placement?.takingAmount
        }
    }

    func filledShares(_ placement: PolymarketOrderPlacement?) -> Decimal? {
        switch model.intent.side {
        case .buy: placement?.takingAmount
        case .sell: placement?.makingAmount
        }
    }

    func orderedMoney(quote: PolymarketOrderQuote?) -> Decimal? {
        switch model.intent {
        case .buy: model.state.enteredAmount
        case .sell: quote?.expectedExecutionAmount
        }
    }

    func executionPrice(_ placement: PolymarketOrderPlacement?) -> Decimal? {
        guard let money = filledMoney(placement), let shares = filledShares(placement), shares > 0 else {
            return nil
        }

        return money / shares
    }

    func makeResultContent(
        placement: PolymarketOrderPlacement?,
        quote: PolymarketOrderQuote?
    ) -> PolymarketOrderResultViewModel.Content {
        .init(
            market: marketRow,
            placedAt: Date(),
            orderedAmount: orderedMoney(quote: quote),
            filledAmount: filledMoney(placement),
            tokensBought: filledShares(placement),
            resolutionDate: model.market.endDate,
            executionPrice: executionPrice(placement),
            side: model.intent.side,
            feeText: PolymarketOrderFormatter.money(quote?.fees.total)
        )
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
        let gate = PolymarketOrderGate(state: state, intent: model.intent)

        header = Self.makeHeader(state: state, intent: model.intent, account: account)
        feeText = Self.makeFeeText(state: state)

        if let quote = state.quote.quote {
            marketRow = .make(
                market: model.market,
                outcome: model.outcome,
                eventTitle: model.eventTitle,
                averagePrice: quote.averagePrice
            )
        }
        slippageText = PolymarketSlippageFormatter.rowText(state.slippagePercent)
        notifications = gate.notifications
        isPlaceEnabled = gate.isPrimaryButtonEnabled
        isFeeBreakdownAvailable = state.quote.quote != nil
    }
}

// MARK: - Copy

extension PolymarketOrderSummaryViewModel {
    var screenTitle: String {
        switch model.intent {
        case .buy: Localization.predictionPlaceSummaryTitle
        case .sell: Localization.predictionCloseTitle
        }
    }

    var primaryActionTitle: String {
        switch model.intent {
        case .buy: Localization.predictionPlaceButton
        case .sell: Localization.predictionCloseButton
        }
    }
}

// MARK: - Mapping

private extension PolymarketOrderSummaryViewModel {
    // [REDACTED_TODO_COMMENT]
    static func makeHeader(
        state: PolymarketOrderModel.State,
        intent: PolymarketOrderIntent,
        account: PolymarketOrderAccount?
    ) -> PolymarketOrderSummaryHeader.Model {
        let isSell = intent.side == .sell

        return .make(
            account: account,
            amountText: isSell
                ? PolymarketOrderFormatter.shares(state.enteredAmount) + " shares"
                : PolymarketOrderFormatter.enteredAmount(state.enteredAmount),
            balanceText: isSell
                ? Localization.commonBalance(PolymarketOrderFormatter.shares(state.balance) + " shares")
                : Localization.commonBalance(PolymarketOrderFormatter.money(state.balance)),
            toWin: makeToWin(state: state, intent: intent),
            isProceeds: isSell
        )
    }

    static func makeToWin(
        state: PolymarketOrderModel.State,
        intent: PolymarketOrderIntent
    ) -> PolymarketAmountBadge.State? {
        guard let quote = state.quote.quote else { return nil }

        switch intent {
        case .buy, .sell: return .value(PolymarketOrderFormatter.money(quote.expectedExecutionAmount))
        }
    }

    static func makeFeeText(state: PolymarketOrderModel.State) -> String {
        PolymarketOrderFormatter.money(state.quote.quote?.fees.total)
    }
}

// MARK: - PlacementAnomaly

private extension PolymarketOrderSummaryViewModel {
    enum PlacementAnomaly: Error {
        case matchedWithoutFill
    }
}

// MARK: - Constants

private extension PolymarketOrderSummaryViewModel {
    enum Constants {
        static let maxQuoteAge: TimeInterval = 30
    }
}

// MARK: - Cancellation

private extension PolymarketOrderPlacementError {
    var isUserCancellation: Bool {
        guard case .notSent(let underlying) = self else { return false }

        if let signing = underlying as? PolymarketSigningError, case .cancelled = signing {
            return true
        }

        return underlying is CancellationError
    }
}
