//
//  ActionButtonsViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import CombineExt
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

    private let userWalletModel: UserWalletModel
    private let swapAvailabilityChecker: SwapAvailabilityChecker
    private var latestWalletModelsCount = 0

    init(
        coordinator: some ActionButtonsRoutable,
        userWalletModel: some UserWalletModel,
        swapAvailabilityChecker: SwapAvailabilityChecker
    ) {
        self.userWalletModel = userWalletModel
        self.swapAvailabilityChecker = swapAvailabilityChecker

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
        AccountWalletModelsAggregator
            .walletModelsPublisher(from: userWalletModel.accountModelsManager)
            .withWeakCaptureOf(self)
            .sink { viewModel, walletModels in
                viewModel.handleWalletModelsCountUpdate(walletModels.count)
            }
            .store(in: &bag)
    }

    func handleWalletModelsCountUpdate(_ walletModelsCount: Int) {
        latestWalletModelsCount = walletModelsCount

        if walletModelsCount == 0 {
            disabledAllButtons()
        } else {
            restoreButtonsState()
        }
    }

    func disabledAllButtons() {
        runTask(in: self) { @MainActor viewModel in
            viewModel.buyActionButtonViewModel.updateState(to: .disabled)
            viewModel.sellActionButtonViewModel.updateState(to: .disabled)
            viewModel.swapActionButtonViewModel.updateState(to: .disabled)
        }
    }

    func restoreButtonsState() {
        let lastExpressUpdatingState = expressAvailabilityProvider.expressAvailabilityUpdateStateValue
        updateSwapButtonState(expressUpdateState: lastExpressUpdatingState)
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
        case .restricted, .loading, .initial, .disabled, .unavailable:
            break
        }
    }

    @MainActor
    func handleBuyUpdatedState() {
        buyActionButtonViewModel.updateState(
            to: latestWalletModelsCount == 0 ? .disabled : .idle
        )
    }
}

// MARK: - Swap

private extension ActionButtonsViewModel {
    func bindSwapAvailability() {
        let walletModelsActionsUpdatePublisher = AccountWalletModelsAggregator
            .walletModelsPublisher(from: userWalletModel.accountModelsManager)
            .flatMapLatest { walletModels in
                guard !walletModels.isEmpty else {
                    return AnyPublisher.just
                }

                return walletModels
                    .map(\.actionsUpdatePublisher)
                    .merge()
            }

        expressAvailabilityProvider
            .expressAvailabilityUpdateState
            .combineLatest(walletModelsActionsUpdatePublisher)
            .withWeakCaptureOf(self)
            .sink { viewModel, input in
                // `walletModelsActionsUpdatePublisher` acts just as a trigger to re-evaluate swap button state
                let (expressUpdateState, _) = input
                viewModel.updateSwapButtonState(expressUpdateState: expressUpdateState)
            }
            .store(in: &bag)
    }

    func bindSwapUnreadNotificationBadge() {
        storyAvailabilityService
            .availableStoriesPublisher
            .combineLatest(swapActionButtonViewModel.$viewState)
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { input in
                let (viewModel, (_, swapButtonViewState)) = input
                let swapStoryAvailable = viewModel.storyAvailabilityService.checkStoryAvailability(storyId: .swap)
                let buttonStateIsValid = swapButtonViewState == .idle || swapButtonViewState == .initial
                viewModel.shouldShowSwapUnreadNotificationBadge = buttonStateIsValid && swapStoryAvailable
            }
            .store(in: &bag)
    }

    func updateSwapButtonState(expressUpdateState: ExpressAvailabilityUpdateState) {
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
        case .restricted, .loading, .initial, .disabled, .unavailable:
            break
        }
    }

    @MainActor
    func handleUpdatedSwapState() {
        switch swapAvailableWalletModelsCount() {
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

    func swapAvailableWalletModelsCount() -> Int {
        AccountWalletModelsAggregator
            .walletModels(from: userWalletModel.accountModelsManager)
            .filter { swapAvailabilityChecker.isSwapAvailable(walletModel: $0) }
            .count
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
        case .restricted, .loading, .initial, .disabled, .unavailable:
            break
        }
    }

    @MainActor
    func handleSellUpdatedState() {
        sellActionButtonViewModel.updateState(
            to: latestWalletModelsCount == 0 ? .disabled : .idle
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
