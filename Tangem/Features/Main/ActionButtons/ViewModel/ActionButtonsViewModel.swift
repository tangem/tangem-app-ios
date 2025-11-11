//
//  ActionButtonsViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import TangemLocalization
import Foundation
import TangemFoundation
import TangemStories

typealias ActionButtonsRoutable = ActionButtonsBuyFlowRoutable & ActionButtonsSellFlowRoutable & ActionButtonsSwapFlowRoutable

final class ActionButtonsViewModel: ObservableObject {
    // MARK: Dependencies

    @Injected(\.sellService)
    private var sellService: SellService

    @Injected(\.expressAvailabilityProvider)
    private var expressAvailabilityProvider: ExpressAvailabilityProvider

    @Injected(\.hotCryptoService)
    private var hotCryptoService: HotCryptoService

    @Injected(\.storyAvailabilityService)
    private var storyAvailabilityService: any StoryAvailabilityService

    // MARK: Button ViewModels

    let buyActionButtonViewModel: BuyActionButtonViewModel
    let sellActionButtonViewModel: SellActionButtonViewModel
    let swapActionButtonViewModel: SwapActionButtonViewModel

    @Published private(set) var shouldShowSwapUnreadNotificationBadge = false

    // MARK: Private properties

    private var bag = Set<AnyCancellable>()
    private let lastButtonTapped = PassthroughSubject<ActionButtonModel, Never>()

    private var lastSellInitializeState: SellServiceState?

    private let expressTokensListAdapter: ExpressTokensListAdapter
    private let userWalletModel: UserWalletModel

    init(
        coordinator: some ActionButtonsRoutable,
        expressTokensListAdapter: some ExpressTokensListAdapter,
        userWalletModel: some UserWalletModel
    ) {
        self.expressTokensListAdapter = expressTokensListAdapter
        self.userWalletModel = userWalletModel

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

        buyActionButtonViewModel = BuyActionButtonViewModel(
            model: .buy,
            coordinator: coordinator,
            lastButtonTapped: lastButtonTapped,
            userWalletModel: userWalletModel
        )

        bind()
    }

    deinit {
        AppLogger.debug(self, "deinit")
    }

    func refresh() {
        hotCryptoService.loadHotCrypto(AppSettings.shared.selectedCurrencyCode)
        // do nothing if already iniitialized
        sellService.initialize()
    }
}

// MARK: - Bind

private extension ActionButtonsViewModel {
    func bind() {
        bindWalletModels()
        bindBuyAvailability()
        bindSwapAvailability()
        bindSwapUnreadNotificationBadge()
        bindSellAvailability()
    }

    func bindWalletModels() {
        // accounts_fixes_needed_action_buttons
        userWalletModel
            .walletModelsManager
            .walletModelsPublisher
            .withWeakCaptureOf(self)
            .sink { viewModel, walletModels in
                runTask(in: viewModel) { @MainActor viewModel in
                    if walletModels.isEmpty {
                        viewModel.disabledAllButtons()
                    } else {
                        viewModel.restoreButtonsState()
                    }
                }
            }
            .store(in: &bag)
    }

    @MainActor
    private func disabledAllButtons() {
        buyActionButtonViewModel.updateState(to: .disabled)
        sellActionButtonViewModel.updateState(to: .disabled)
        swapActionButtonViewModel.updateState(to: .disabled)
    }

    @MainActor
    private func restoreButtonsState() {
        let lastExpressUpdatingState = expressAvailabilityProvider.expressAvailabilityUpdateStateValue
        updateSwapButtonState(lastExpressUpdatingState)
        updateBuyButtonStateWithExpress(lastExpressUpdatingState)

        if let lastSellInitializeState {
            updateSellButtonState(lastSellInitializeState)
        }
    }
}

// MARK: - Buy

private extension ActionButtonsViewModel {
    func bindBuyAvailability() {
        expressAvailabilityProvider
            .expressAvailabilityUpdateState
            .withWeakCaptureOf(self)
            .sink { viewModel, expressUpdateState in
                viewModel.updateBuyButtonStateWithExpress(expressUpdateState)
            }
            .store(in: &bag)
    }

    func updateBuyButtonStateWithExpress(_ expressUpdateState: ExpressAvailabilityUpdateState) {
        runTask(in: self) { @MainActor viewModel in
            let hasCache = viewModel.expressAvailabilityProvider.hasCache

            switch (expressUpdateState, hasCache) {
            case (_, true):
                viewModel.handleBuyUpdatedState()
            case (.updating, false):
                viewModel.handleBuyUpdatingState()
            case (.updated, false):
                viewModel.handleBuyUpdatedState()
            case (.failed, false):
                viewModel.buyActionButtonViewModel.updateState(
                    to: .restricted(reason: Localization.actionButtonsSomethingWrongAlertMessage)
                )
            }
        }
    }

    @MainActor
    func handleBuyUpdatingState() {
        switch buyActionButtonViewModel.viewState {
        case .idle:
            buyActionButtonViewModel.updateState(to: .initial)
        case .restricted, .loading, .initial, .disabled:
            break
        }
    }

    @MainActor
    func handleBuyUpdatedState() {
        // accounts_fixes_needed_action_buttons
        buyActionButtonViewModel.updateState(
            to: userWalletModel.walletModelsManager.walletModels.isEmpty ? .disabled : .idle
        )
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

    func bindSwapUnreadNotificationBadge() {
        storyAvailabilityService
            .availableStoriesPublisher
            .combineLatest(swapActionButtonViewModel.$viewState)
            .receive(on: DispatchQueue.main)
            .sink { [weak self, storyAvailabilityService] _, swapButtonViewState in
                let swapStoryAvailable = storyAvailabilityService.checkStoryAvailability(storyId: .swap)
                let buttonStateIsValid = swapButtonViewState == .idle || swapButtonViewState == .initial
                self?.shouldShowSwapUnreadNotificationBadge = buttonStateIsValid && swapStoryAvailable
            }
            .store(in: &bag)
    }

    func updateSwapButtonState(_ expressUpdateState: ExpressAvailabilityUpdateState) {
        runTask(in: self) { @MainActor viewModel in
            let hasCache = viewModel.expressAvailabilityProvider.hasCache

            switch (expressUpdateState, hasCache) {
            case (_, true):
                viewModel.handleUpdatedSwapState()
            case (.updating, false):
                viewModel.handleUpdatingSwapState()
            case (.updated, false):
                viewModel.handleUpdatedSwapState()
            case (.failed, false):
                viewModel.swapActionButtonViewModel.updateState(
                    to: .restricted(reason: Localization.actionButtonsSomethingWrongAlertMessage)
                )
            }
        }
    }

    @MainActor
    func handleUpdatingSwapState() {
        switch swapActionButtonViewModel.viewState {
        case .idle:
            swapActionButtonViewModel.updateState(to: .initial)
        case .restricted, .loading, .initial, .disabled:
            break
        }
    }

    @MainActor
    func handleUpdatedSwapState() {
        // accounts_fixes_needed_action_buttons
        let walletModelsCount = userWalletModel.walletModelsManager.walletModels.count

        switch walletModelsCount {
        case 0:
            swapActionButtonViewModel.updateState(to: .disabled)
        case 1:
            swapActionButtonViewModel.updateState(
                to: .restricted(
                    reason: Localization.actionButtonsSwapNotEnoughTokensAlertMessage
                )
            )
        default:
            swapActionButtonViewModel.updateState(to: .idle)
        }
    }
}

// MARK: - Sell

private extension ActionButtonsViewModel {
    func bindSellAvailability() {
        sellService
            .initializationPublisher
            .withWeakCaptureOf(self)
            .sink { viewModel, sellServiceState in
                viewModel.updateSellButtonState(sellServiceState)
            }
            .store(in: &bag)
    }

    func updateSellButtonState(_ sellServiceState: SellServiceState) {
        runTask(in: self) { @MainActor viewModel in
            viewModel.lastSellInitializeState = sellServiceState

            switch sellServiceState {
            case .initializing: viewModel.handleSellUpdatingState()
            case .initialized: viewModel.handleSellUpdatedState()
            case .failed(let error): viewModel.handleFailedSellState(error)
            }
        }
    }

    @MainActor
    func handleSellUpdatingState() {
        switch sellActionButtonViewModel.viewState {
        case .idle:
            sellActionButtonViewModel.updateState(to: .initial)
        case .restricted, .loading, .initial, .disabled:
            break
        }
    }

    @MainActor
    func handleSellUpdatedState() {
        // accounts_fixes_needed_action_buttons
        sellActionButtonViewModel.updateState(
            to: userWalletModel.walletModelsManager.walletModels.isEmpty ? .disabled : .idle
        )
    }

    @MainActor
    func handleFailedSellState(_ error: SellServiceState.SellServiceError) {
        switch error {
        case .networkError:
            sellActionButtonViewModel.updateState(
                to: .restricted(reason: error.localizedDescription)
            )
        case .countryNotSupported:
            sellActionButtonViewModel.updateState(to: .idle)
        }
    }
}

// MARK: - CustomStringConvertible

extension ActionButtonsViewModel: CustomStringConvertible {
    var description: String {
        objectDescription(self)
    }
}
