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
import TangemUI
import TangemUIUtils

final class PolymarketCoordinator: CoordinatorObject, SendFeeCurrencyNavigating {
    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: FloatingSheetPresenter
    @Injected(\.safariManager) private var safariManager: SafariManager
    private let presenceStore: PolymarketAccountPresenceStore = AppSettings.shared

    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Root ViewModels

    @Published private(set) var viewState: ViewState?
    @Published var destination: Destination?
    @Published var sendCoordinator: SendCoordinator? {
        didSet {
            guard sendCoordinator == nil, hasDispatchedDeposit else { return }

            hasDispatchedDeposit = false
            startAwaitingFunds()
        }
    }

    @Published var tokenDetailsCoordinator: TokenDetailsCoordinator?

    private let onboardingFactory = PolymarketOnboardingFactory()
    private var geoblockStateProvider: PolymarketGeoblockStateProvider?
    private var balanceProvider: PolymarketBalanceProvider?

    private var userWalletModel: (any UserWalletModel)?
    private var addFundsInteractor: PolymarketAddFundsInteractor?
    private weak var regionWarning: PolymarketRegionRestrictionViewModel?
    private weak var addFundsSheet: PolymarketAddFundsSheetViewModel?
    private var hasDispatchedDeposit = false

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

        Task { @MainActor in
            openEntry(for: options.userWalletModel)
        }
    }
}

// MARK: - Entry

private extension PolymarketCoordinator {
    func openEntry(for userWalletModel: any UserWalletModel) {
        let state = PolymarketAccountAggregator.polymarketAccountModel(from: userWalletModel.accountModelsManager)?.state

        guard state == .active else {
            openWelcome(for: userWalletModel, hasExistingAccount: hasExistingAccount(state, for: userWalletModel))
            return
        }

        openPolymarketMain()
    }

    func hasExistingAccount(_ state: PolymarketAccountState?, for userWalletModel: any UserWalletModel) -> Bool {
        state == .syncNeeded || presenceStore.hasAccount(userWalletId: userWalletModel.userWalletId)
    }

    func openWelcome(for userWalletModel: any UserWalletModel, hasExistingAccount: Bool) {
        viewState = .welcome(PolymarketWelcomeViewModel(
            interactor: onboardingFactory.makeInteractor(for: userWalletModel),
            hasExistingAccount: hasExistingAccount,
            coordinator: self
        ))
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
    func openPolymarketMain() {
        let geoblockStateProvider = CommonPolymarketGeoblockStateProvider(
            geoblockService: PolymarketOnboardingServicesFactory.makeDefault().makeGeoblockService()
        )

        let balanceProvider = CommonPolymarketBalanceProvider(userWalletModel: userWalletModel)
        let addFundsInteractor = userWalletModel.map { PolymarketAddFundsFactory().makeInteractor(for: $0) }

        self.geoblockStateProvider = geoblockStateProvider
        self.balanceProvider = balanceProvider
        self.addFundsInteractor = addFundsInteractor

        viewState = .feed(PolymarketMainViewModel(
            apiProvider: PolymarketAPIProviderFactory().makeProvider(),
            geoblockStateProvider: geoblockStateProvider,
            balanceProvider: balanceProvider,
            addFundsInteractor: addFundsInteractor,
            coordinator: self
        ))
    }

    func openLegalTerms(url: URL) {
        safariManager.openURL(url)
    }
}

// MARK: - PolymarketMainRoutable protocol conformance

extension PolymarketCoordinator: PolymarketMainRoutable {
    func dismiss() {
        dismissAction(())
    }

    func openEventDetails(eventID: String, category: PolymarketCategory?) {
        destination = .eventDetails(PolymarketEventDetailsViewModel(
            eventID: eventID,
            category: category,
            apiProvider: PolymarketAPIProviderFactory().makeProvider(),
            coordinator: self
        ))
    }

    func openOrder(market: PolymarketMarket, outcome: PolymarketOutcome) {
        guard let geoblockStateProvider, let balanceProvider else {
            PolymarketLogger.error(
                "An outcome was tapped before the feed built its providers",
                error: CoordinatorError.missingOrderProviders
            )
            return
        }

        let coordinator = PolymarketOrderCoordinator(
            dismissAction: { [weak self] in
                self?.destination = nil
            }
        )

        coordinator.start(with: .init(
            market: market,
            outcome: outcome,
            geoblockStateProvider: geoblockStateProvider,
            balancePublisher: balanceProvider.collateralPublisher
        ))

        destination = .order(coordinator)
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

            guard let addFundsInteractor else {
                PolymarketLogger.error(
                    "Add funds was tapped before the feed built its interactor",
                    error: CoordinatorError.missingAddFundsInteractor
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
                interactor: addFundsInteractor,
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
}

// MARK: - PolymarketAddFundsSheetRoutable protocol conformance

extension PolymarketCoordinator: PolymarketAddFundsSheetRoutable {
    func openReceiveSheet(viewModel: ReceiveMainViewModel) {
        Task { @MainActor [weak self] in
            guard let self else { return }

            // Dismiss the active Add funds sheet first, otherwise Receive is queued behind it and never shown.
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
            openSwap(parameters: parameters)
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
    func openSwap(parameters: PredefinedSwapParameters) {
        let coordinator = makeSendCoordinator()

        coordinator.start(
            with: .init(
                type: .swap(parameters),
                source: .main,
                onTransactionDispatched: { [weak self] in self?.hasDispatchedDeposit = true }
            )
        )

        sendCoordinator = coordinator
    }

    func startAwaitingFunds() {
        guard case .feed(let viewModel) = viewState else { return }

        viewModel.startAwaitingFunds()
    }
}

// MARK: - PolymarketEventDetailsRoutable protocol conformance

extension PolymarketCoordinator: PolymarketEventDetailsRoutable {
    func dismissEventDetails() {
        destination = nil
    }
}

// MARK: - Errors

extension PolymarketCoordinator {
    enum CoordinatorError: Error {
        case missingUserWalletModel
        case missingAddFundsInteractor
        case missingOrderProviders
        case missingPolymarketAccountModel
    }
}

// MARK: - View state

extension PolymarketCoordinator {
    enum ViewState {
        case welcome(PolymarketWelcomeViewModel)
        case feed(PolymarketMainViewModel)
    }
}

// MARK: - Navigation

extension PolymarketCoordinator {
    enum Destination {
        case eventDetails(PolymarketEventDetailsViewModel)
        case order(PolymarketOrderCoordinator)
    }
}
