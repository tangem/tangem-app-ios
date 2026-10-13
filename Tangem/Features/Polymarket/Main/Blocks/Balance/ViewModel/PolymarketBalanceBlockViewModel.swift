//
//  PolymarketBalanceBlockViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine
import TangemFoundation
import TangemLocalization
import TangemUI
import TangemUIUtils

final class PolymarketBalanceBlockViewModel: ObservableObject {
    @Published private(set) var balance: LoadableBalanceView.State = .loading(cached: .none)
    @Published private(set) var balanceMode: PolymarketBalanceDisplay.Mode = .available
    @Published private(set) var canSwitchBalanceMode = false
    @Published private(set) var addFundsState: PolymarketAccountFundsInteractor.AddFundsAvailability = .loading
    @Published private(set) var withdrawState: WithdrawState = .loading
    @Published var alert: AlertBinder?

    var isBalanceLoading: Bool {
        if case .loading(.none) = balance {
            return true
        }

        return false
    }

    var balanceModeTitle: String {
        switch balanceMode {
        case .available: Localization.predictionMainAvailableBalance
        case .total: Localization.predictionMainTotalBalance
        }
    }

    var isAddFundsEnabled: Bool {
        addFundsState == .available
    }

    var isWithdrawEnabled: Bool {
        withdrawState.isAvailable
    }

    private let balanceProvider: PolymarketBalanceProvider
    private let isRegionRestricted: () -> Bool
    private weak var routable: PolymarketBalanceBlockRoutable?

    private let refresher: PolymarketBalanceRefresher
    private let actionsAvailability: PolymarketBalanceActionsAvailability
    private let alertBuilder = PolymarketBalanceBlockAlertBuilder()

    private var display = PolymarketBalanceDisplay()
    private var bag: Set<AnyCancellable> = []

    init(
        balanceProvider: PolymarketBalanceProvider,
        accountFundsInteractor: PolymarketAccountFundsInteractor,
        fundsArrivalTracker: PolymarketFundsArrivalTracker,
        isRegionRestricted: @escaping () -> Bool,
        refreshCenter: PolymarketMainRefreshCenter,
        routable: PolymarketBalanceBlockRoutable
    ) {
        self.balanceProvider = balanceProvider
        self.isRegionRestricted = isRegionRestricted
        self.routable = routable

        refresher = PolymarketBalanceRefresher(
            balanceProvider: balanceProvider,
            fundsArrivalTracker: fundsArrivalTracker
        )
        actionsAvailability = PolymarketBalanceActionsAvailability(
            accountFundsInteractor: accountFundsInteractor,
            collateralBalancePublisher: balanceProvider.collateralBalancePublisher
        )

        bind()
        refreshCenter.register { [weak self] scope in
            await self?.refresh(scope: scope)
        }
        refresher.start()
        actionsAvailability.start { [weak self] states in
            self?.addFundsState = states.addFunds
            self?.withdrawState = states.withdraw
        }
    }
}

// MARK: - View actions

extension PolymarketBalanceBlockViewModel {
    func handleViewAction(_ action: ViewAction) {
        switch action {
        case .toggleBalanceMode:
            display.toggleMode()
            applyDisplay()
        case .openAddFunds:
            openAddFunds()
        case .openWithdraw:
            openWithdraw()
        }
    }

    enum ViewAction {
        case toggleBalanceMode
        case openAddFunds
        case openWithdraw
    }
}

// MARK: - Actions

private extension PolymarketBalanceBlockViewModel {
    func openAddFunds() {
        guard !isRegionRestricted() else {
            routable?.openRegionWarning()
            return
        }

        switch addFundsState {
        case .available:
            routable?.openAddFunds()
        case .loading:
            break
        case .unavailable:
            alert = alertBuilder.makeAddFundsUnavailableAlert { [weak self] in
                self?.actionsAvailability.prepare()
            }
        }
    }

    func openWithdraw() {
        switch withdrawState {
        case .available:
            routable?.openWithdraw()
        case .loading:
            break
        case .unavailable(let reason):
            alert = alertBuilder.makeWithdrawUnavailableAlert(reason: reason) { [weak self] in
                self?.retryWithdrawAvailability(after: reason)
            }
        }
    }

    func retryWithdrawAvailability(after reason: WithdrawUnavailability) {
        switch reason {
        case .emptyBalance, .tooSmallBalance:
            break
        case .balanceUnavailable:
            refresher.refreshNow()
        case .accountUnavailable, .minimumUnknown:
            actionsAvailability.prepare()
        }
    }
}

// MARK: - Binding

private extension PolymarketBalanceBlockViewModel {
    func bind() {
        balanceProvider
            .balancePublisher
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, formatted in
                viewModel.display.update(available: formatted)
                viewModel.applyDisplay()
            }
            .store(in: &bag)

        balanceProvider
            .totalBalancePublisher
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, formatted in
                viewModel.display.update(total: formatted)
                viewModel.applyDisplay()
            }
            .store(in: &bag)
    }

    @MainActor
    func refresh(scope: PolymarketMainRefreshCenter.Scope) async {
        switch scope {
        case .full:
            actionsAvailability.prepare()
            await refresher.refresh()
        case .balance:
            await refresher.refresh()
        case .accountFunds:
            actionsAvailability.prepare()
        }
    }

    func applyDisplay() {
        canSwitchBalanceMode = display.canSwitchMode
        balanceMode = display.mode

        if let state = display.state {
            balance = state
        }
    }
}

// MARK: - Types

extension PolymarketBalanceBlockViewModel {
    enum WithdrawState: Equatable {
        case loading
        case available
        case unavailable(WithdrawUnavailability)

        var isAvailable: Bool {
            self == .available
        }
    }

    enum WithdrawUnavailability: Equatable {
        case emptyBalance
        case tooSmallBalance(minimumFormatted: String)
        case balanceUnavailable
        case accountUnavailable
        case minimumUnknown
    }
}
