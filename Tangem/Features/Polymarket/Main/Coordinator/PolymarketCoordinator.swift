//
//  PolymarketCoordinator.swift
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
import TangemStories
import TangemUI
import TangemUIUtils

final class PolymarketCoordinator: CoordinatorObject, SendFeeCurrencyNavigating {
    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: FloatingSheetPresenter
    @Injected(\.floatingSheetPresentingStateProvider) private var sheetStateProvider: FloatingSheetPresentingStateProvider
    @Injected(\.safariManager) private var safariManager: SafariManager
    @Injected(\.tangemStoriesPresenter) private var tangemStoriesPresenter: any TangemStoriesPresenter

    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Root ViewModels

    @Published private(set) var viewState: ViewState?
    @Published var destination: Destination?

    @Published var redeem: PolymarketRedeemViewModel?
    let orderPresenter = PolymarketOrderPresenter()

    private var orderPresenterSubscription: AnyCancellable?
    @Published var sheet: Sheet? {
        didSet {
            guard sheet == nil else { return }

            startAwaitingDispatchedOperation()
        }
    }

    var tokenDetailsCoordinator: TokenDetailsCoordinator? {
        get {
            guard case .tokenDetails(let coordinator) = destination else { return nil }

            return coordinator
        }
        set { destination = newValue.map { .tokenDetails($0) } }
    }

    var sendCoordinator: SendCoordinator? {
        get {
            guard case .send(let coordinator) = sheet else { return nil }

            return coordinator
        }
        set { sheet = newValue.map { .send($0) } }
    }

    private var options: Options?
    private var redeemService: PolymarketRedeeming?
    private var signingButtonType: SigningActionButtonViewType = .holdToConfirm
    private weak var regionWarning: PolymarketRegionRestrictionViewModel?
    private weak var addFundsSheet: PolymarketAddFundsSheetViewModel?
    private var sheetDismissSubscription: AnyCancellable?
    private var dispatchedOperation: FundingOperation?
    private var dispatchedBalance: Decimal?

    // MARK: - Init

    required init(
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction

        orderPresenter.mainCoordinator = self
        orderPresenterSubscription = orderPresenter.objectWillChange.sink { [weak self] in
            self?.objectWillChange.send()
        }
    }

    func start(with options: Options) {
        self.options = options

        subscribeToSheetDismiss()

        Task { @MainActor in
            openEntry(for: options.userWalletModel)
        }
    }
}

// MARK: - Entry

private extension PolymarketCoordinator {
    func subscribeToSheetDismiss() {
        sheetDismissSubscription = sheetStateProvider
            .hasPresentedSheetPublisher
            .filter { !$0 }
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { coordinator, _ in
                coordinator.addFundsSheet = nil
                coordinator.regionWarning = nil
            }
    }

    @MainActor
    func openEntry(for userWalletModel: any UserWalletModel) {
        let state = AccountModelsAggregator(.polymarket).model(from: userWalletModel.accountModelsManager)?.state

        guard state == .active else {
            viewState = .welcome(PolymarketOnboardingFactory().makeWelcomeViewModel(for: userWalletModel, coordinator: self))
            return
        }

        showMain(for: userWalletModel)
    }
}

// MARK: - Options

extension PolymarketCoordinator {
    struct Options {
        let userWalletModel: any UserWalletModel
    }
}

// MARK: - PolymarketWelcomeRoutable protocol conformance

extension PolymarketCoordinator: PolymarketWelcomeRoutable {
    func onboardingDidFinish(isNewAccount: Bool) {
        Task { @MainActor in
            guard let userWalletModel = options?.userWalletModel else { return }

            guard isNewAccount else {
                showMain(for: userWalletModel)
                return
            }

            tangemStoriesPresenter.present(
                story: .polymarketOnboarding(.initialWithoutImages),
                analyticsSource: .predictions,
                presentCompletion: { [weak self] in self?.showMain(for: userWalletModel) }
            )
        }
    }

    func openLegalTerms(url: URL) {
        safariManager.openURL(url)
    }
}

// MARK: - The main screen

private extension PolymarketCoordinator {
    @MainActor
    func showMain(for userWalletModel: any UserWalletModel) {
        let dependencies = PolymarketMainDependenciesFactory().make(for: userWalletModel)

        redeemService = dependencies.redeemService
        signingButtonType = dependencies.signingButtonType

        let activityService = dependencies.activityService
        Task { await activityService.reconcileDeposits() }
        Task { await dependencies.withdrawContext.tracker.resume() }

        viewState = .main(
            viewModel: dependencies.makeMainViewModel(routable: self),
            destinationFactory: PolymarketDestinationFactory(
                dependencies: dependencies,
                onAddFunds: { [weak self] in self?.openAddFunds() },
                onRegionWarning: { [weak self] in self?.openRegionWarning() },
                onReturnToMain: { [weak self] in self?.popToMainTop() },
                orderPresenter: orderPresenter
            ),
            fundingFlow: PolymarketFundingFlow(dependencies: dependencies)
        )
    }
}

// MARK: - PolymarketMainScreenRoutable

extension PolymarketCoordinator: PolymarketMainScreenRoutable {
    func dismiss() {
        dismissAction(())
    }

    @MainActor
    func openHowItWorks() {
        tangemStoriesPresenter.presentOnDemand(
            story: .polymarketOnboarding(.initialWithoutImages),
            analyticsSource: .predictions
        )
    }

    @MainActor
    func openSupportChat() {
        guard let userWalletModel = options?.userWalletModel else { return }

        sheet = .supportChat(SupportChatViewModel(input: PolymarketSupportChatInputFactory().makeInput(for: userWalletModel)))
    }

    @MainActor
    func openActivity() {
        guard let destinationFactory = viewState?.destinationFactory else { return }

        destination = .activity(destinationFactory.makeActivity(onClose: { [weak self] in self?.popToMain() }))
    }

    func openEventDetails(
        eventID: String,
        category: PolymarketCategory?,
        onOrderPlaced: @escaping @MainActor (PolymarketOrderIndexing) -> Void
    ) {
        guard let destinationFactory = viewState?.destinationFactory else { return }

        destination = .eventDetails(destinationFactory.makeEventDetailsCoordinator(
            eventID: eventID,
            category: category,
            onOrderPlaced: onOrderPlaced,
            onRegionWarning: { [weak self] in self?.openRegionWarning() },
            onClose: { [weak self] in self?.popToMain() }
        ))
    }

    @MainActor
    func openRedeem(position: PolymarketPosition, onClaimed: @escaping (PolymarketPosition?) -> Void) {
        guard let redeemService else { return }

        redeem = PolymarketRedeemViewModel(
            position: position,
            redeemService: redeemService,
            signingButtonType: signingButtonType,
            onClaimed: onClaimed,
            coordinator: self
        )
    }

    func openPositionDetails(position: PolymarketPosition, onOrderPlaced: @escaping @MainActor (PolymarketOrderIndexing) -> Void) {
        openPositionDetails(position: position, onOrderPlaced: onOrderPlaced, scrollsMainToTopOnClose: false)
    }

    private func openPositionDetails(
        position: PolymarketPosition,
        onOrderPlaced: @escaping @MainActor (PolymarketOrderIndexing) -> Void,
        scrollsMainToTopOnClose: Bool
    ) {
        guard destination == nil else {
            replaceDestination { [weak self] in
                self?.openPositionDetails(position: position, onOrderPlaced: onOrderPlaced, scrollsMainToTopOnClose: scrollsMainToTopOnClose)
            }
            return
        }

        guard let destinationFactory = viewState?.destinationFactory else { return }

        destination = .positionDetails(destinationFactory.makePositionDetails(
            position: position,
            onOrderPlaced: onOrderPlaced,
            onRegionWarning: { [weak self] in self?.openRegionWarning() },
            onClose: { [weak self] in
                if scrollsMainToTopOnClose {
                    self?.popToMainTop()
                } else {
                    self?.popToMain()
                }
            }
        ))
    }

    func openOrder(
        market: PolymarketMarket,
        outcome: PolymarketOutcome,
        eventTitle: String,
        request: PolymarketOrderRequest,
        onPlaced: @escaping @MainActor (PolymarketOrderIndexing) -> Void
    ) {
        guard let destinationFactory = viewState?.destinationFactory else { return }

        let coordinator = destinationFactory.makeOrderCoordinator(
            market: market,
            outcome: outcome,
            eventTitle: eventTitle,
            request: request,
            onPlaced: onPlaced,
            onOpenPosition: { [weak self] position in
                self?.openPositionDetails(position: position, onOrderPlaced: onPlaced, scrollsMainToTopOnClose: true)
                self?.orderPresenter.dismiss()
            },
            onClose: { [weak self] in self?.orderPresenter.dismiss() }
        )

        destinationFactory.presentOrder(coordinator, from: nil)
    }

    @MainActor
    func openMyPositions(
        tab: PolymarketPositionsTab,
        onOrderPlaced: @escaping @MainActor (PolymarketOrderIndexing) -> Void,
        onClaimed: @escaping (PolymarketPosition?) -> Void
    ) {
        guard let destinationFactory = viewState?.destinationFactory else { return }

        destination = .myPositions(
            destinationFactory.makeMyPositions(
                tab: tab,
                onOrderPlaced: onOrderPlaced,
                onClaimed: onClaimed,
                onRegionWarning: { [weak self] in self?.openRegionWarning() },
                onClose: { [weak self] in self?.popToMain() }
            )
        )
    }

    func openRegionWarning() {
        guard regionWarning == nil else { return }

        Task { @MainActor [weak self] in
            guard let self else { return }

            let viewModel = PolymarketRegionRestrictionViewModel.regionRestriction(
                onClose: { [weak self] in self?.floatingSheetPresenter.removeActiveSheet() }
            )

            regionWarning = viewModel
            floatingSheetPresenter.enqueue(sheet: viewModel)
        }
    }

    func openAddFunds() {
        Task { @MainActor [weak self] in
            guard let self, addFundsSheet == nil, let fundingFlow = viewState?.fundingFlow else { return }

            guard !fundingFlow.isRegionBlocked else {
                openRegionWarning()
                return
            }

            do {
                let viewModel = try fundingFlow.makeAddFundsSheet(routable: self)

                addFundsSheet = viewModel
                floatingSheetPresenter.enqueue(sheet: viewModel)
            } catch {
                PolymarketLogger.error("Add funds is not available", error: error)
            }
        }
    }

    func openWithdraw() {
        guard let fundingFlow = viewState?.fundingFlow else { return }

        runTask(in: self) { coordinator in
            do {
                let source = try fundingFlow.makeWithdrawSource()
                let parameters = try await fundingFlow.makeWithdrawParameters(from: source)

                await runOnMain { coordinator.openSwap(parameters: parameters, operation: .withdrawal) }
            } catch {
                PolymarketLogger.error("Withdraw is not available", error: error)
            }
        }
    }
}

// MARK: - PolymarketAddFundsSheetRoutable

extension PolymarketCoordinator: PolymarketAddFundsSheetRoutable {
    func openChooseNetworkSheet(networks: [PolymarketDepositNetwork]) {
        Task { @MainActor [weak self] in
            guard let self else { return }

            addFundsSheet = nil
            floatingSheetPresenter.removeActiveSheet()
            floatingSheetPresenter.enqueue(
                sheet: PolymarketChooseNetworkSheetViewModel(networks: networks, coordinator: self)
            )
        }
    }

    func openSwapFlow(parameters: PredefinedSwapParameters) {
        Task { @MainActor [weak self] in
            guard let self else { return }

            addFundsSheet = nil
            floatingSheetPresenter.removeActiveSheet()
            openSwap(parameters: parameters, operation: .deposit)
        }
    }

    func closeAddFundsSheet() {
        Task { @MainActor [weak self] in
            self?.addFundsSheet = nil
            self?.floatingSheetPresenter.removeActiveSheet()
        }
    }
}

// MARK: - PolymarketChooseNetworkSheetRoutable

extension PolymarketCoordinator: PolymarketChooseNetworkSheetRoutable {
    func chooseNetworkSheetRequestReceive(input: PolymarketReceiveSheetViewModel.Input) {
        Task { @MainActor [weak self] in
            guard let self else { return }

            floatingSheetPresenter.removeActiveSheet()
            floatingSheetPresenter.enqueue(
                sheet: PolymarketReceiveSheetViewModel(input: input, coordinator: self)
            )
        }
    }

    func closeChooseNetworkSheet() {
        Task { @MainActor [weak self] in
            self?.floatingSheetPresenter.removeActiveSheet()
        }
    }
}

// MARK: - PolymarketReceiveSheetRoutable

extension PolymarketCoordinator: PolymarketReceiveSheetRoutable {
    func closeReceiveSheet() {
        Task { @MainActor [weak self] in
            self?.floatingSheetPresenter.removeActiveSheet()
        }
    }
}

// MARK: - Swap

private extension PolymarketCoordinator {
    func openSwap(parameters: PredefinedSwapParameters, operation: FundingOperation) {
        let coordinator = makeSendCoordinator()

        coordinator.start(
            with: .init(
                type: .swap(parameters),
                source: .main,
                onTransactionDispatched: { [weak self] in self?.transactionDispatched(operation) }
            )
        )

        sendCoordinator = coordinator
    }

    func transactionDispatched(_ operation: FundingOperation) {
        dispatchedOperation = operation

        dispatchedBalance = viewState?.fundingFlow?.currentBalance
    }

    func startAwaitingDispatchedOperation() {
        let baseline = dispatchedBalance
        dispatchedBalance = nil

        guard let operation = dispatchedOperation, let fundingFlow = viewState?.fundingFlow else { return }

        dispatchedOperation = nil

        switch operation {
        case .deposit:
            fundingFlow.awaitDeposit(since: baseline)
        case .withdrawal:
            fundingFlow.awaitWithdrawal(since: baseline)
        }
    }
}

// MARK: - FeeCurrencyNavigating

extension PolymarketCoordinator {
    func openFeeCurrency(for walletModel: any WalletModel, userWalletModel: UserWalletModel) {
        guard destination != nil else {
            pushFeeCurrencyTokenDetails(for: walletModel, userWalletModel: userWalletModel)
            return
        }

        popToMain()

        Task { @MainActor [weak self] in
            self?.pushFeeCurrencyTokenDetails(for: walletModel, userWalletModel: userWalletModel)
        }
    }
}

// MARK: - PolymarketRedeemRoutable protocol conformance

extension PolymarketCoordinator: PolymarketRedeemRoutable {
    func closeRedeem() {
        redeem = nil
    }
}

// MARK: - Navigation

extension PolymarketCoordinator {
    func replaceDestination(with push: @escaping () -> Void) {
        destination = nil

        Task { @MainActor in
            push()
        }
    }

    func popToMain() {
        destination = nil
    }

    func popToMainTop() {
        popToMain()
        viewState?.mainViewModel?.scrollToTop()
    }
}

// MARK: - Funding operations

extension PolymarketCoordinator {
    enum FundingOperation {
        case deposit
        case withdrawal
    }
}

// MARK: - View state

extension PolymarketCoordinator {
    enum ViewState {
        case welcome(PolymarketWelcomeViewModel)
        case main(
            viewModel: PolymarketMainViewModel,
            destinationFactory: PolymarketDestinationFactory,
            fundingFlow: PolymarketFundingFlow
        )

        var mainViewModel: PolymarketMainViewModel? {
            guard case .main(let viewModel, _, _) = self else { return nil }

            return viewModel
        }

        var destinationFactory: PolymarketDestinationFactory? {
            guard case .main(_, let destinationFactory, _) = self else { return nil }

            return destinationFactory
        }

        var fundingFlow: PolymarketFundingFlow? {
            guard case .main(_, _, let fundingFlow) = self else { return nil }

            return fundingFlow
        }
    }
}

// MARK: - Navigation

extension PolymarketCoordinator {
    enum Destination {
        case eventDetails(PolymarketEventDetailsCoordinator)
        case positionDetails(PolymarketPositionDetailsCoordinator)
        case myPositions(PolymarketMyPositionsCoordinator)
        case tokenDetails(TokenDetailsCoordinator)
        case activity(PolymarketActivityCoordinator)
    }

    enum Sheet: Identifiable {
        case send(SendCoordinator)
        case supportChat(SupportChatViewModel)

        var id: String {
            switch self {
            case .send: "send"
            case .supportChat: "supportChat"
            }
        }
    }
}
