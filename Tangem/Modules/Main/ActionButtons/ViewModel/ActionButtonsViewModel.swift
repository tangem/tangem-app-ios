//
//  ActionButtonsViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation

typealias ActionButtonsRoutable = ActionButtonsBuyFlowRoutable & ActionButtonsSellFlowRoutable & ActionButtonsSwapFlowRoutable

final class ActionButtonsViewModel: ObservableObject {
    // MARK: Dependencies

    @Injected(\.exchangeService)
    private var exchangeService: ExchangeService & CombinedExchangeService

    @Injected(\.expressAvailabilityProvider)
    private var expressAvailabilityProvider: ExpressAvailabilityProvider

    // MARK: Published properties

    @Published private(set) var isButtonsDisabled = false

    // MARK: Button ViewModels

    let buyActionButtonViewModel: BuyActionButtonViewModel
    let sellActionButtonViewModel: SellActionButtonViewModel
    let swapActionButtonViewModel: SwapActionButtonViewModel

    // MARK: Private properties

    private var bag = Set<AnyCancellable>()
    private let lastButtonTapped = PassthroughSubject<ActionButtonModel, Never>()

    private var currentSwapUpdateState: ExpressAvailabilityUpdateState?
    private let expressTokensListAdapter: ExpressTokensListAdapter
    private let userWalletModel: UserWalletModel

    init(
        coordinator: some ActionButtonsRoutable,
        expressTokensListAdapter: some ExpressTokensListAdapter,
        userWalletModel: some UserWalletModel
    ) {
        self.expressTokensListAdapter = expressTokensListAdapter
        self.userWalletModel = userWalletModel

        buyActionButtonViewModel = BuyActionButtonViewModel(
            model: .buy,
            coordinator: coordinator,
            lastButtonTapped: lastButtonTapped,
            userWalletModel: userWalletModel
        )

        sellActionButtonViewModel = SellActionButtonViewModel(
            model: .sell,
            coordinator: coordinator,
            lastButtonTapped: lastButtonTapped,
            userWalletModel: userWalletModel
        )

        swapActionButtonViewModel = SwapActionButtonViewModel(
            model: .swap,
            coordinator: coordinator,
            lastButtonTapped: lastButtonTapped,
            userWalletModel: userWalletModel
        )

        bind()
    }

    func refresh() {
        exchangeService.initialize()

        expressAvailabilityProvider.updateExpressAvailability(
            for: userWalletModel.walletModelsManager.walletModels.map(\.tokenItem),
            forceReload: false,
            userWalletId: userWalletModel.userWalletId.stringValue
        )
    }
}

// MARK: - Bind

private extension ActionButtonsViewModel {
    func bind() {
        bindWalletModels()
        bindSwapAvailability()
        bindExchangeAvailability()
    }

    func bindWalletModels() {
        userWalletModel
            .walletModelsManager
            .walletModelsPublisher
            .withWeakCaptureOf(self)
            .sink { viewModel, walletModels in
                TangemFoundation.runTask(in: self) { @MainActor viewModel in
                    if walletModels.isEmpty {
                        viewModel.buyActionButtonViewModel.updateState(to: .disabled)
                        viewModel.sellActionButtonViewModel.updateState(to: .disabled)
                        viewModel.swapActionButtonViewModel.updateState(to: .disabled)
                    } else if let currentSwapUpdateState = viewModel.currentSwapUpdateState {
                        viewModel.updateSwapButtonState(currentSwapUpdateState)
                    }
                }
            }
            .store(in: &bag)
    }
}

// MARK: - Swap

private extension ActionButtonsViewModel {
    func bindSwapAvailability() {
        expressAvailabilityProvider
            .expressAvailabilityUpdateState
            .withWeakCaptureOf(self)
            .sink { viewModel, expressUpdateState in
                viewModel.updateSwapButtonState(expressUpdateState)
            }
            .store(in: &bag)
    }

    func updateSwapButtonState(_ expressUpdateState: ExpressAvailabilityUpdateState) {
        TangemFoundation.runTask(in: self) { @MainActor viewModel in
            viewModel.currentSwapUpdateState = expressUpdateState

            switch expressUpdateState {
            case .updating: viewModel.handleUpdatingExpressState()
            case .updated: viewModel.handleUpdatedSwapState()
            case .failed:
                viewModel.swapActionButtonViewModel.updateState(
                    to: .restricted(reason: Localization.actionButtonsSomethingWrongAlertMessage)
                )

                viewModel.buyActionButtonViewModel.updateState(
                    to: .restricted(reason: Localization.actionButtonsSomethingWrongAlertMessage)
                )
            }
        }
    }

    @MainActor
    func handleUpdatingExpressState() {
        switch swapActionButtonViewModel.viewState {
        case .idle:
            swapActionButtonViewModel.updateState(to: .loading)
            buyActionButtonViewModel.updateState(to: .loading)
        case .restricted, .loading, .initial, .disabled:
            break
        }
    }

    @MainActor
    func handleUpdatedSwapState() {
        let walletModels = userWalletModel.walletModelsManager.walletModels

        buyActionButtonViewModel.updateState(to: .idle)

        if walletModels.count > 1 {
            swapActionButtonViewModel.updateState(to: .idle)
        } else {
            swapActionButtonViewModel.updateState(
                to: .restricted(
                    reason: Localization.actionButtonsSwapNotEnoughTokensAlertMessage
                )
            )
        }
    }
}

// MARK: - Sell

private extension ActionButtonsViewModel {
    func bindExchangeAvailability() {
        exchangeService
            .sellInitializationPublisher
            .withWeakCaptureOf(self)
            .sink { viewModel, exchangeServiceState in
                viewModel.updateSellButtonState(exchangeServiceState)
            }
            .store(in: &bag)
    }

    func updateSellButtonState(_ exchangeServiceState: ExchangeServiceState) {
        TangemFoundation.runTask(in: self) { @MainActor viewModel in

            if let disabledLocalizedReason = viewModel.userWalletModel.config.getDisabledLocalizedReason(
                for: .exchange
            ) {
                viewModel.sellActionButtonViewModel.updateState(to: .restricted(reason: disabledLocalizedReason))
                return
            }

            switch exchangeServiceState {
            case .initializing: viewModel.sellActionButtonViewModel.updateState(to: .initial)
            case .initialized: viewModel.sellActionButtonViewModel.updateState(to: .idle)
            case .failed(let error): viewModel.handleFailedSellState(error)
            }
        }
    }

    @MainActor
    func handleFailedSellState(_ error: ExchangeServiceState.ExchangeServiceError) {
        sellActionButtonViewModel.updateState(
            to: .restricted(reason: error.localizedDescription)
        )
    }
}
