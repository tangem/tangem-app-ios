//
//  PolymarketOrderCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation
import TangemPolymarket
import TangemPolymarketUI

final class PolymarketOrderCoordinator: CoordinatorObject {
    @Injected(\.safariManager) private var safariManager: SafariManager
    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: FloatingSheetPresenter
    @Injected(\.mailComposePresenter) private var mailPresenter: MailComposePresenter

    let dismissAction: Action<DismissPayload?>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Root ViewModels

    @Published private(set) var viewModel: PolymarketOrderViewModel?

    private var model: PolymarketOrderModel?

    // MARK: - Child ViewModels

    @Published var destination: Destination?
    @Published var sheet: Sheet?

    @Published var positionDetailsCoordinator: PolymarketPositionDetailsCoordinator?

    private var placementService: PolymarketOrderPlacementService?
    private var account: PolymarketOrderAccount?
    private weak var positionBuilder: PolymarketOrderFlowBuilder?
    private var regionWarningAction: (() -> Void)?
    private var placedAction: (@MainActor (PolymarketOrderIndexing) -> Void)?
    private var addFundsAction: (() -> Void)?
    private var indexingTask: PolymarketOrderIndexing?
    private var isMarketClosedPresented = false
    private var isQuoteUnavailablePresented = false

    // MARK: - Init

    required init(
        dismissAction: @escaping Action<DismissPayload?>,
        popToRootAction: @escaping Action<PopToRootOptions> = { _ in }
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        placementService = options.placementService
        account = options.account
        positionBuilder = options.positionBuilder
        regionWarningAction = options.onRegionWarning
        placedAction = options.onPlaced
        addFundsAction = options.onAddFunds

        Task { @MainActor in
            let model = PolymarketOrderModel(
                market: options.market,
                outcome: options.outcome,
                eventTitle: options.eventTitle,
                intent: options.intent,
                apiProvider: PolymarketAPIProviderFactory().makeProvider(walletId: options.walletId),
                geoblockStateProvider: options.geoblockStateProvider,
                positionsService: options.positionsService,
                clobService: options.clobService,
                isAwaitingFundsPublisher: options.isAwaitingFundsPublisher,
                collateralBalancePublisher: options.collateralBalancePublisher
            )

            self.model = model
            viewModel = PolymarketOrderViewModel(model: model, coordinator: self)
        }
    }
}

// MARK: - PolymarketOrderRoutable protocol conformance

extension PolymarketOrderCoordinator: PolymarketOrderRoutable {
    func closeOrder() {
        dismiss(with: DismissPayload(position: nil))
    }

    func returnToMain() {
        dismiss(with: DismissPayload(position: nil, returnsToMain: true))
    }

    func openAddFunds() {
        addFundsAction?()
    }

    @MainActor
    func openMarketClosed() {
        guard !isMarketClosedPresented else { return }

        isMarketClosedPresented = true

        floatingSheetPresenter.enqueue(sheet: PolymarketRegionRestrictionViewModel.marketClosed(
            onClose: { [weak self] in
                self?.floatingSheetPresenter.removeActiveSheet()
                self?.closeOrder()
            }
        ))
    }

    @MainActor
    func openQuoteUnavailable() {
        guard !isQuoteUnavailablePresented else { return }

        isQuoteUnavailablePresented = true

        floatingSheetPresenter.enqueue(sheet: PolymarketRegionRestrictionViewModel.quoteUnavailable(
            onClose: { [weak self] in
                self?.floatingSheetPresenter.removeActiveSheet()
                self?.closeOrder()
            }
        ))
    }

    func openPosition(_ position: PolymarketPosition) {
        guard let positionBuilder else {
            dismiss(with: DismissPayload(position: position))
            return
        }

        positionDetailsCoordinator = positionBuilder.makePositionDetails(
            position: position,
            onOrderPlaced: { [weak self] indexing in
                self?.indexingTask = indexing
                self?.placedAction?(indexing)
            },
            onRegionWarning: { [weak self] in self?.regionWarningAction?() },
            onClose: { [weak self] in self?.returnToMain() }
        )
    }

    func openSlippageSelector(percent: Decimal, onConfirm: @escaping (Decimal) -> Void) {
        sheet = .slippageSelector(PolymarketSlippageSelectorViewModel(percent: percent) { [weak self] confirmed in
            onConfirm(confirmed)
            self?.sheet = nil
        })
    }

    @MainActor
    func openSummary(model: PolymarketOrderModel) {
        guard let placementService else { return }

        destination = .summary(PolymarketOrderSummaryViewModel(
            model: model,
            account: account,
            placementService: placementService,
            coordinator: self
        ))
    }
}

// MARK: - Navigation

extension PolymarketOrderCoordinator {
    func popToAmount() {
        destination = nil
    }
}

// MARK: - PolymarketOrderSummaryRoutable protocol conformance

extension PolymarketOrderCoordinator: PolymarketOrderSummaryRoutable {
    func closeSummary() {
        popToAmount()
    }

    func openLegalTerms(url: URL) {
        safariManager.openURL(url)
    }

    func openSupport() {
        let logsComposer = LogsComposer(infoProvider: BaseDataCollector())
        let mailViewModel = MailViewModel(
            logsComposer: logsComposer,
            recipient: EmailConfig.default.recipient,
            emailType: .appFeedback(subject: EmailConfig.default.subject)
        )

        Task { @MainActor in
            mailPresenter.present(viewModel: mailViewModel)
        }
    }

    @MainActor
    func openFeeBreakdown(model: PolymarketOrderModel) {
        sheet = .feeBreakdown(PolymarketFeeBreakdownSheetViewModel(model: model))
    }

    @MainActor
    func openResult(state: PolymarketOrderResultViewModel.State, content: PolymarketOrderResultViewModel.Content) {
        if state != .noFill, let indexing = model?.awaitIndexing() {
            indexingTask = indexing
            placedAction?(indexing)
        }

        destination = .result(PolymarketOrderResultViewModel(
            state: state,
            content: content,
            indexing: indexingTask,
            coordinator: self
        ))
    }
}

// MARK: - PolymarketOrderResultRoutable protocol conformance

extension PolymarketOrderCoordinator: PolymarketOrderResultRoutable {}

// MARK: - Navigation

extension PolymarketOrderCoordinator {
    enum Destination {
        case summary(PolymarketOrderSummaryViewModel)
        case result(PolymarketOrderResultViewModel)
    }
}

// MARK: - Sheets

extension PolymarketOrderCoordinator {
    enum Sheet: Identifiable {
        case slippageSelector(PolymarketSlippageSelectorViewModel)
        case feeBreakdown(PolymarketFeeBreakdownSheetViewModel)

        var id: String {
            switch self {
            case .slippageSelector: "slippageSelector"
            case .feeBreakdown: "feeBreakdown"
            }
        }
    }
}

// MARK: - Options

extension PolymarketOrderCoordinator {
    struct DismissPayload {
        let position: PolymarketPosition?
        var returnsToMain = false
    }

    struct Options {
        let market: PolymarketMarket
        let outcome: PolymarketOutcome
        let eventTitle: String
        let walletId: String
        let account: PolymarketOrderAccount?
        let intent: PolymarketOrderIntent
        let geoblockStateProvider: PolymarketGeoblockStateProvider
        let placementService: PolymarketOrderPlacementService
        let positionsService: PolymarketPositionsService
        let clobService: PolymarketCLOBService
        let isAwaitingFundsPublisher: AnyPublisher<Bool, Never>
        let collateralBalancePublisher: AnyPublisher<Decimal?, Never>
        let positionBuilder: PolymarketOrderFlowBuilder?
        let onPlaced: @MainActor (PolymarketOrderIndexing) -> Void
        let onRegionWarning: () -> Void
        let onAddFunds: () -> Void
    }
}
