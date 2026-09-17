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

final class PolymarketOrderCoordinator: CoordinatorObject {
    @Injected(\.safariManager) private var safariManager: SafariManager
    @Injected(\.mailComposePresenter) private var mailPresenter: MailComposePresenter

    let dismissAction: Action<DismissPayload?>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Root ViewModels

    @Published private(set) var viewModel: PolymarketOrderViewModel?

    private var model: PolymarketOrderModel?

    // MARK: - Child ViewModels

    @Published var destination: Destination?
    @Published var sheet: Sheet?

    private var placementService: PolymarketOrderPlacementService?
    private var addFundsAction: (() -> Void)?
    private var indexingTask: PolymarketOrderIndexing?
    private var hasPlacedOrder = false

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
                isAwaitingFundsPublisher: options.isAwaitingFundsPublisher
            )

            self.model = model
            viewModel = PolymarketOrderViewModel(model: model, coordinator: self)
        }
    }
}

// MARK: - PolymarketOrderRoutable protocol conformance

extension PolymarketOrderCoordinator: PolymarketOrderRoutable {
    func closeOrder() {
        dismiss(with: hasPlacedOrder ? DismissPayload(indexing: indexingTask, position: nil) : nil)
    }

    func openAddFunds() {
        addFundsAction?()
    }

    func openPosition(_ position: PolymarketPosition) {
        dismiss(with: DismissPayload(indexing: indexingTask, position: position))
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
            placementService: placementService,
            coordinator: self
        ))
    }
}

// MARK: - PolymarketOrderSummaryRoutable protocol conformance

extension PolymarketOrderCoordinator: PolymarketOrderSummaryRoutable {
    func closeSummary() {
        destination = nil
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
        hasPlacedOrder = state != .noFill

        if hasPlacedOrder {
            indexingTask = model?.awaitIndexing()
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
        let indexing: PolymarketOrderIndexing?
        let position: PolymarketPosition?
    }

    struct Options {
        let market: PolymarketMarket
        let outcome: PolymarketOutcome
        let eventTitle: String
        let walletId: String
        let intent: PolymarketOrderIntent
        let geoblockStateProvider: PolymarketGeoblockStateProvider
        let placementService: PolymarketOrderPlacementService
        let positionsService: PolymarketPositionsService?
        let isAwaitingFundsPublisher: AnyPublisher<Bool, Never>
        let onAddFunds: () -> Void
    }
}
