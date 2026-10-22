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
import TangemUI

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
    let signingButtonType: SigningActionButtonViewType

    // MARK: - Dependencies

    private let model: PolymarketOrderModel
    private let account: PolymarketOrderAccount?
    private let submission: PolymarketOrderSubmission
    private weak var coordinator: PolymarketOrderSummaryRoutable?

    private var placementTask: Task<Void, Never>?
    private var bag: Set<AnyCancellable> = []

    // MARK: - Init

    init(
        model: PolymarketOrderModel,
        account: PolymarketOrderAccount?,
        placementService: PolymarketOrderPlacementService,
        signingButtonType: SigningActionButtonViewType,
        coordinator: PolymarketOrderSummaryRoutable?
    ) {
        self.model = model
        self.account = account
        submission = PolymarketOrderSubmission(model: model, placementService: placementService)
        self.signingButtonType = signingButtonType
        self.coordinator = coordinator

        marketRow = .make(
            market: model.market,
            outcome: model.outcome,
            eventTitle: model.eventTitle,
            entryPrice: model.entryPriceForVote
        )
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
        case .onAppear, .onDisappear:
            break
        case .close:
            guard !isPlacing else { return }

            coordinator?.closeOrder()
        case .goBack:
            guard !isPlacing else { return }

            coordinator?.closeSummary()
        case .placeOrder:
            place()
        case .openFeeBreakdown:
            openFeeBreakdown()
        case .openLegalTerms(let url):
            coordinator?.openLegalTerms(url: url)
        }
    }
}

// MARK: - ViewAction

extension PolymarketOrderSummaryViewModel {
    enum ViewAction {
        case onAppear
        case onDisappear
        case goBack
        case close
        case placeOrder
        case openFeeBreakdown
        case openLegalTerms(URL)
    }
}

// MARK: - Placement

private extension PolymarketOrderSummaryViewModel {
    func place() {
        guard !isPlacing else { return }

        switch submission.readiness() {
        case .unavailable:
            return
        case .staleQuote:
            reportStaleQuote()
        case .ready(let quote):
            isPlacing = true

            placementTask = Task { @MainActor [weak self] in
                guard let self else { return }

                handle(await submission.submit(quote: quote) { self.marketRow })
            }
        }
    }

    func handle(_ outcome: PolymarketOrderSubmission.Outcome) {
        switch outcome {
        case .cancelled:
            resume()
        case .failed(let returningToMain):
            reportFailure(returningToMain: returningToMain)
        case .finished(let state, let content):
            isPlacing = false
            coordinator?.openResult(state: state, content: content)
        }
    }

    func reportFailure(returningToMain: Bool) {
        if !returningToMain {
            resume()
        }

        alert = PolymarketOrderSubmission.failureAlert(
            returningToMain: returningToMain,
            onSupport: { [weak self] in self?.coordinator?.openSupport() },
            onClose: { [weak self] in self?.coordinator?.closeOrder() }
        )
    }

    func reportStaleQuote() {
        resume()
        alert = PolymarketOrderSubmission.staleQuoteAlert { [weak self] in self?.coordinator?.closeSummary() }
    }

    func resume() {
        isPlacing = false
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

        if state.quote.isResuming {
            marketRow = marketRow.settling(nextPriceText: nil, isLoading: true)
        } else if let quote = state.quote.quote {
            marketRow = .make(
                market: model.market,
                outcome: model.outcome,
                eventTitle: model.eventTitle,
                averagePrice: quote.averagePrice,
                entryPrice: model.entryPriceForVote
            )
        } else if marketRow.isOutcomeNextPriceLoading {
            marketRow = marketRow.settling(nextPriceText: nil, isLoading: false)
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
        let balance = isSell ? state.collateralBalance : state.balance

        return .make(
            account: account,
            sourceTitle: isSell ? Localization.predictionCloseSummaryTo : Localization.predictionPlaceSummaryFrom,
            amountText: isSell
                ? PolymarketOrderFormatter.money(state.quote.quote?.expectedExecutionAmount)
                : PolymarketOrderFormatter.enteredAmount(state.enteredAmount),
            balanceText: Localization.commonBalance(PolymarketOrderFormatter.money(balance)),
            toWin: isSell ? nil : makeToWin(state: state, intent: intent),
            caption: isSell ? makeSellingCaption(state: state) : nil
        )
    }

    static func makeSellingCaption(state: PolymarketOrderModel.State) -> String {
        Localization.predictionCloseSellingTokens(PolymarketOrderFormatter.shares(state.enteredAmount))
    }

    static func makeToWin(
        state: PolymarketOrderModel.State,
        intent: PolymarketOrderIntent
    ) -> PolymarketAmountBadge.State? {
        guard let quote = state.quote.quote else { return nil }

        return .value(PolymarketOrderFormatter.money(quote.expectedExecutionAmount))
    }

    static func makeFeeText(state: PolymarketOrderModel.State) -> String {
        PolymarketOrderFormatter.money(state.quote.quote?.fees.total)
    }
}
