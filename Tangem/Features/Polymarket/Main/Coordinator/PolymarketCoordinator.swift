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
import TangemUIUtils

final class PolymarketCoordinator: CoordinatorObject {
    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: FloatingSheetPresenter
    @Injected(\.safariManager) private var safariManager: SafariManager
    private let presenceStore: PolymarketAccountPresenceStore = AppSettings.shared

    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Root ViewModels

    @Published private(set) var viewState: ViewState?
    @Published var destination: Destination?

    private let onboardingFactory = PolymarketOnboardingFactory()

    private var userWalletModel: (any UserWalletModel)?
    private weak var regionWarning: PolymarketRegionRestrictionViewModel?

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
        refreshPolymarketAccount()

        viewState = .feed(PolymarketMainViewModel(
            apiProvider: PolymarketAPIProviderFactory().makeProvider(),
            geoblockService: PolymarketOnboardingServicesFactory.makeDefault().makeGeoblockService(),
            balanceProvider: makeBalancePublisher(),
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
        let coordinator = PolymarketOrderCoordinator(
            dismissAction: { [weak self] in
                self?.destination = nil
            }
        )

        coordinator.start(with: .init(market: market, outcome: outcome))
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
}

// MARK: - PolymarketEventDetailsRoutable protocol conformance

extension PolymarketCoordinator: PolymarketEventDetailsRoutable {
    func dismissEventDetails() {
        destination = nil
    }
}

// MARK: - The Polymarket account

private extension PolymarketCoordinator {
    func refreshPolymarketAccount() {
        guard
            let accountModelsManager = userWalletModel?.accountModelsManager,
            let polymarketAccountModel = PolymarketAccountAggregator.polymarketAccountModel(from: accountModelsManager)
        else {
            return
        }

        runTask { await polymarketAccountModel.refreshState() }
    }

    func makeBalancePublisher() -> AnyPublisher<FormattedTokenBalanceType, Never> {
        guard
            let accountModelsManager = userWalletModel?.accountModelsManager,
            let accountModel = PolymarketAccountAggregator.polymarketAccountModel(from: accountModelsManager)
        else {
            return .just(output: .failure(.empty(BalanceFormatter.defaultEmptyBalanceString)))
        }

        return accountModel.fiatTotalTokenBalanceProvider.formattedBalanceTypePublisher
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
