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
    @Published var tokenDetailsCoordinator: TokenDetailsCoordinator?
    @Published var sendCoordinator: SendCoordinator? {
        didSet {
            guard sendCoordinator == nil, let operation = dispatchedOperation else { return }

            dispatchedOperation = nil

            switch operation {
            case .deposit:
                startAwaitingFunds()
            case .withdrawal:
                startAwaitingWithdrawal()
            }
        }
    }

    private var geoblockStateProvider: PolymarketGeoblockStateProvider?
    private var balanceProvider: PolymarketBalanceProvider?

    private var userWalletModel: (any UserWalletModel)?
    private var accountFundsInteractor: PolymarketAccountFundsInteractor?
    private var withdrawContext: PolymarketWithdrawContext?
    private weak var regionWarning: PolymarketRegionRestrictionViewModel?
    private weak var addFundsSheet: PolymarketAddFundsSheetViewModel?
    private var sheetDismissSubscription: AnyCancellable?
    private var dispatchedOperation: FundingOperation?

    // MARK: - Init

    required init(
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        userWalletModel = options.userWalletModel

        subscribeToSheetDismiss()

        Task { @MainActor in
            openEntry(for: options.userWalletModel)
        }
    }
}

// MARK: - Entry

private extension PolymarketCoordinator {
    /// A sheet dismissed by tapping the dimmed background never reaches the coordinator, and the view it
    /// was rendered in outlives the dismissal, so every reference guarding a reopen has to be released by
    /// what is on screen rather than by what is still in memory.
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
        let state = PolymarketAccountAggregator.polymarketAccountModel(from: userWalletModel.accountModelsManager)?.state

        guard state == .active else {
            viewState = .welcome(PolymarketOnboardingFactory().makeWelcomeViewModel(for: userWalletModel, coordinator: self))
            return
        }

        showMain()
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
            guard isNewAccount else {
                showMain()
                return
            }

            tangemStoriesPresenter.present(
                story: .polymarketOnboarding(.initialWithoutImages),
                analyticsSource: .predictions,
                presentCompletion: { [weak self] in self?.showMain() }
            )
        }
    }

    func openLegalTerms(url: URL) {
        safariManager.openURL(url)
    }
}

// MARK: - The main screen

private extension PolymarketCoordinator {
    func showMain() {
        guard let userWalletModel else {
            PolymarketLogger.error("The feed was opened without a wallet", error: CoordinatorError.missingUserWalletModel)
            dismiss()
            return
        }

        let geoblockStateProvider = CommonPolymarketGeoblockStateProvider(
            geoblockService: PolymarketOnboardingServicesFactory.makeDefault().makeGeoblockService()
        )

        let balanceProvider = CommonPolymarketBalanceProvider(userWalletModel: userWalletModel)
        let accountFundsInteractor = PolymarketAccountFundsFactory().makeInteractor(for: userWalletModel)

        self.geoblockStateProvider = geoblockStateProvider
        self.balanceProvider = balanceProvider
        self.accountFundsInteractor = accountFundsInteractor
        withdrawContext = PolymarketWithdrawFactory().makeContext(for: userWalletModel)

        viewState = .main(PolymarketMainViewModel(
            apiProvider: makeAPIProvider(for: userWalletModel),
            geoblockStateProvider: geoblockStateProvider,
            balanceProvider: balanceProvider,
            accountFundsInteractor: accountFundsInteractor,
            positionsService: makePositionsService(for: userWalletModel),
            coordinator: self
        ))
    }

    func makeAPIProvider(for userWalletModel: any UserWalletModel) -> PolymarketAPIProvider {
        PolymarketAPIProviderFactory().makeProvider(walletId: userWalletModel.userWalletId.stringValue)
    }

    func makePositionsService(for userWalletModel: any UserWalletModel) -> PolymarketPositionsService {
        PolymarketPositionsFactory().makeService(for: userWalletModel, apiProvider: makeAPIProvider(for: userWalletModel))
    }
}

// MARK: - PolymarketMainRoutable protocol conformance

extension PolymarketCoordinator: PolymarketMainRoutable {
    func dismiss() {
        dismissAction(())
    }

    @MainActor
    func openHowItWorks() {
        tangemStoriesPresenter.present(
            story: .polymarketOnboarding(.initialWithoutImages),
            analyticsSource: .predictions,
            presentCompletion: {}
        )
    }

    func openEventDetails(
        eventID: String,
        category: PolymarketCategory?,
        onOrderPlaced: @escaping @MainActor (Task<Void, Never>?) -> Void
    ) {
        guard let userWalletModel else {
            PolymarketLogger.error("An event was tapped without a wallet", error: CoordinatorError.missingUserWalletModel)
            return
        }

        let coordinator = PolymarketEventDetailsCoordinator(
            dismissAction: { [weak self] in self?.destination = nil }
        )

        coordinator.start(with: .init(
            eventID: eventID,
            category: category,
            apiProvider: makeAPIProvider(for: userWalletModel),
            geoblockStateProvider: geoblockStateProvider,
            onOrderPlaced: onOrderPlaced,
            onRegionWarning: { [weak self] in self?.openRegionWarning() },
            orderBuilder: self
        ))

        destination = .eventDetails(coordinator)
    }

    func openPositionDetails(position: PolymarketPosition) {
        destination = .positionDetails(PolymarketPositionDetailsViewModel(position: position, coordinator: self))
    }

    func openOrder(
        market: PolymarketMarket,
        outcome: PolymarketOutcome,
        eventTitle: String,
        onPlaced: @escaping @MainActor (Task<Void, Never>?) -> Void
    ) {
        guard let coordinator = makeOrderCoordinator(
            market: market,
            outcome: outcome,
            eventTitle: eventTitle,
            onPlaced: onPlaced,
            onClose: { [weak self] in self?.destination = nil }
        ) else {
            return
        }

        destination = .order(coordinator)
    }

    @MainActor
    func openMyPositions(tab: PolymarketPositionsTab) {
        guard let userWalletModel else {
            PolymarketLogger.error("The positions were opened without a wallet", error: CoordinatorError.missingUserWalletModel)
            return
        }

        let coordinator = PolymarketMyPositionsCoordinator(
            dismissAction: { [weak self] in self?.destination = nil }
        )

        coordinator.start(with: .init(tab: tab, positionsService: makePositionsService(for: userWalletModel)))

        destination = .myPositions(coordinator)
    }

    func openRegionWarning() {
        guard regionWarning == nil else { return }

        Task { @MainActor [weak self] in
            guard let self else { return }

            let viewModel = PolymarketRegionRestrictionViewModel(
                onClose: { [weak self] in self?.floatingSheetPresenter.removeActiveSheet() }
            )

            regionWarning = viewModel
            floatingSheetPresenter.enqueue(sheet: viewModel)
        }
    }

    func openAddFunds() {
        Task { @MainActor [weak self] in
            guard let self, addFundsSheet == nil else { return }

            guard let userWalletModel else {
                PolymarketLogger.error("Add funds was tapped without a wallet", error: CoordinatorError.missingUserWalletModel)
                return
            }

            guard let accountFundsInteractor else {
                PolymarketLogger.error(
                    "Add funds was tapped before the feed built its interactor",
                    error: CoordinatorError.missingAccountFundsInteractor
                )
                return
            }

            guard let accountModel = PolymarketAccountAggregator.polymarketAccountModel(from: userWalletModel.accountModelsManager) else {
                PolymarketLogger.error(
                    "Add funds was tapped without a Polymarket account",
                    error: CoordinatorError.missingPolymarketAccountModel
                )
                return
            }

            let viewModel = PolymarketAddFundsSheetViewModel(
                interactor: accountFundsInteractor,
                swapParametersFactory: PolymarketSwapParametersFactory(
                    userWalletInfo: userWalletModel.userWalletInfo,
                    walletModelsProvider: MainScreenUIOrderedWalletModelsProvider(userWalletModel: userWalletModel),
                    accountModel: accountModel
                ),
                coordinator: self
            )

            addFundsSheet = viewModel
            floatingSheetPresenter.enqueue(sheet: viewModel)
        }
    }

    func openWithdraw() {
        guard let userWalletModel else {
            PolymarketLogger.error("Withdraw was tapped without a wallet", error: CoordinatorError.missingUserWalletModel)
            return
        }

        guard let accountModel = PolymarketAccountAggregator.polymarketAccountModel(from: userWalletModel.accountModelsManager) else {
            PolymarketLogger.error(
                "Withdraw was tapped without a Polymarket account",
                error: CoordinatorError.missingPolymarketAccountModel
            )
            return
        }

        guard let depositWalletAddress = accountFundsInteractor?.state.depositWalletAddress else {
            PolymarketLogger.error(
                "Withdraw was tapped before the deposit wallet was verified",
                error: CoordinatorError.missingVerifiedDepositWallet
            )
            return
        }

        guard let withdrawContext else {
            PolymarketLogger.error(
                "Withdraw was tapped before the feed built its context",
                error: CoordinatorError.missingWithdrawContext
            )
            return
        }

        let source = withdrawContext.makeSource(
            accountModel: accountModel,
            depositWalletAddress: depositWalletAddress,
            minimumUSD: accountFundsInteractor?.state.depositTarget?.asset.minimumDepositUSD
        )

        let walletModelsProvider = MainScreenUIOrderedWalletModelsProvider(userWalletModel: userWalletModel)

        runTask(in: self) { coordinator in
            let receiveToken = await PolymarketWithdrawDestinationResolver(
                userWalletInfo: userWalletModel.userWalletInfo,
                walletModelsProvider: walletModelsProvider
            )
            .resolve()

            let parameters = PolymarketSwapParametersFactory(
                userWalletInfo: userWalletModel.userWalletInfo,
                walletModelsProvider: walletModelsProvider,
                accountModel: accountModel
            )
            .make(withdrawingFrom: source, receiveToken: receiveToken)

            await runOnMain { coordinator.openSwap(parameters: parameters, operation: .withdrawal) }
        }
    }
}

// MARK: - PolymarketAddFundsSheetRoutable protocol conformance

extension PolymarketCoordinator: PolymarketAddFundsSheetRoutable {
    func openReceiveSheet(viewModel: ReceiveMainViewModel) {
        Task { @MainActor [weak self] in
            guard let self else { return }

            addFundsSheet = nil
            floatingSheetPresenter.removeActiveSheet()
            floatingSheetPresenter.enqueue(sheet: viewModel)
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

// MARK: - Swap

private extension PolymarketCoordinator {
    func openSwap(parameters: PredefinedSwapParameters, operation: FundingOperation) {
        let coordinator = makeSendCoordinator()

        coordinator.start(
            with: .init(
                type: .swap(parameters),
                source: .main,
                onTransactionDispatched: { [weak self] in self?.dispatchedOperation = operation }
            )
        )

        sendCoordinator = coordinator
    }

    func startAwaitingFunds() {
        guard case .main(let viewModel) = viewState else { return }

        viewModel.startAwaitingFunds()
    }

    func startAwaitingWithdrawal() {
        guard case .main(let viewModel) = viewState else { return }

        viewModel.startAwaitingWithdrawal()
    }
}

// MARK: - PolymarketOrderFlowBuilder protocol conformance

extension PolymarketCoordinator: PolymarketOrderFlowBuilder {
    func makeOrderCoordinator(
        market: PolymarketMarket,
        outcome: PolymarketOutcome,
        eventTitle: String,
        onPlaced: @escaping @MainActor (Task<Void, Never>?) -> Void,
        onClose: @escaping () -> Void
    ) -> PolymarketOrderCoordinator? {
        guard let geoblockStateProvider, let balanceProvider, let userWalletModel else {
            PolymarketLogger.error(
                "An outcome was tapped before the feed built its providers",
                error: CoordinatorError.missingOrderProviders
            )
            return nil
        }

        let coordinator = PolymarketOrderCoordinator(
            dismissAction: { payload in
                onClose()

                guard let payload else { return }

                Task { @MainActor in
                    onPlaced(payload.indexing)
                }
            }
        )

        coordinator.start(with: .init(
            market: market,
            outcome: outcome,
            eventTitle: eventTitle,
            walletId: userWalletModel.userWalletId.stringValue,
            geoblockStateProvider: geoblockStateProvider,
            balancePublisher: balanceProvider.collateralBalancePublisher.map(\.value).eraseToAnyPublisher(),
            placementService: PolymarketOrderPlacementFactory().makeService(for: userWalletModel),
            positionsService: makePositionsService(for: userWalletModel)
        ))

        return coordinator
    }
}

// MARK: - PolymarketPositionDetailsRoutable protocol conformance

extension PolymarketCoordinator: PolymarketPositionDetailsRoutable {
    func closePositionDetails() {
        destination = nil
    }
}

// MARK: - Funding operations

extension PolymarketCoordinator {
    enum FundingOperation {
        case deposit
        case withdrawal
    }
}

// MARK: - Errors

extension PolymarketCoordinator {
    enum CoordinatorError: Error {
        case missingUserWalletModel
        case missingAccountFundsInteractor
        case missingVerifiedDepositWallet
        case missingWithdrawContext
        case missingOrderProviders
        case missingPolymarketAccountModel
    }
}

// MARK: - View state

extension PolymarketCoordinator {
    enum ViewState {
        case welcome(PolymarketWelcomeViewModel)
        case main(PolymarketMainViewModel)
    }
}

// MARK: - Navigation

extension PolymarketCoordinator {
    enum Destination {
        case eventDetails(PolymarketEventDetailsCoordinator)
        case positionDetails(PolymarketPositionDetailsViewModel)
        case myPositions(PolymarketMyPositionsCoordinator)
        case order(PolymarketOrderCoordinator)
    }
}
