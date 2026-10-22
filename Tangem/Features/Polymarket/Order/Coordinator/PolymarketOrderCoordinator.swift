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
import TangemUI

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
    @Published private(set) var inPlaceResult: PolymarketOrderResultViewModel?
    @Published var sheet: Sheet?

    var offersPlacedPosition = true
    var onPositionClosed: (() -> Void)?
    var onLeaveClosedPosition: (() -> Void)?

    private var hasClosedPosition = false

    private var placementService: PolymarketOrderPlacementService?
    private var account: PolymarketOrderAccount?
    private var signingButtonType: SigningActionButtonViewType = .holdToConfirm
    private var regionWarningAction: (() -> Void)?
    private var placedAction: (@MainActor (PolymarketOrderIndexing) -> Void)?
    private var addFundsAction: (() -> Void)?
    private var indexingTask: PolymarketOrderIndexing?
    private var isMarketClosedPresented = false
    private var isQuoteUnavailablePresented = false
    private(set) var flowStyle: PolymarketOrderFlowStyle = .summaryStep

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
        signingButtonType = options.signingButtonType
        regionWarningAction = options.onRegionWarning
        placedAction = options.onPlaced
        addFundsAction = options.onAddFunds
        flowStyle = PolymarketOrderFlowStyle(
            isSingleSheetEnabled: options.isSingleSheetEnabled,
            singleSheet: .init(placementService: options.placementService, signingButtonType: options.signingButtonType)
        )

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
                collateralBalancePublisher: options.collateralBalancePublisher,
                addFundsReadinessStream: options.addFundsReadinessStream
            )

            self.model = model

            viewModel = PolymarketOrderViewModel(model: model, flowStyle: flowStyle, coordinator: self)
        }
    }
}

// MARK: - PolymarketOrderRoutable protocol conformance

extension PolymarketOrderCoordinator: PolymarketOrderRoutable {
    func closeOrder() {
        if hasClosedPosition {
            onLeaveClosedPosition?()
        }

        dismiss(with: DismissPayload(position: nil))
    }

    func openAddFunds() {
        addFundsAction?()
    }

    func openRegionWarning() {
        regionWarningAction?()
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
        dismiss(with: DismissPayload(position: position))
    }

    func openSlippageSelector(percent: Decimal, onConfirm: @escaping (Decimal) -> Void) {
        sheet = .slippageSelector(PolymarketSlippageSelectorViewModel(percent: percent, isRedesigned: flowStyle.isSingleSheet) { [weak self] confirmed in
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
            signingButtonType: signingButtonType,
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
        sheet = .feeBreakdown(PolymarketFeeBreakdownSheetViewModel(model: model, includesPartialQuote: flowStyle.isSingleSheet))
    }

    @MainActor
    func openResult(state: PolymarketOrderResultViewModel.State, content: PolymarketOrderResultViewModel.Content) {
        if state != .noFill, let indexing = model?.awaitIndexing() {
            indexingTask = indexing
            placedAction?(indexing)
        }

        let resultViewModel = PolymarketOrderResultViewModel(
            state: state,
            content: content,
            indexing: indexingTask,
            offersPlacedPosition: offersPlacedPosition,
            coordinator: self
        )

        if resultViewModel.closesPosition {
            hasClosedPosition = true
            onPositionClosed?()
        }

        switch flowStyle {
        case .summaryStep:
            destination = .result(resultViewModel)
        case .singleSheet:
            inPlaceResult = resultViewModel
        }
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
    }

    struct Options {
        let market: PolymarketMarket
        let outcome: PolymarketOutcome
        let eventTitle: String
        let walletId: String
        let account: PolymarketOrderAccount?
        let signingButtonType: SigningActionButtonViewType
        let intent: PolymarketOrderIntent
        let isSingleSheetEnabled: Bool
        let geoblockStateProvider: PolymarketGeoblockStateProvider
        let placementService: PolymarketOrderPlacementService
        let positionsService: PolymarketPositionsService
        let clobService: PolymarketCLOBService
        let isAwaitingFundsPublisher: AnyPublisher<Bool, Never>
        let collateralBalancePublisher: AnyPublisher<Decimal?, Never>
        let addFundsReadinessStream: AsyncStream<PolymarketAccountFundsInteractor.State>
        let onPlaced: @MainActor (PolymarketOrderIndexing) -> Void
        let onRegionWarning: () -> Void
        let onAddFunds: () -> Void
    }
}
