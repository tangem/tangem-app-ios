//
//  SwapActionButtonViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import struct TangemUIUtils.AlertBinder

final class SwapActionButtonViewModel: ActionButtonViewModel {
    // MARK: Dependencies

    @Injected(\.expressAvailabilityProvider)
    private var expressAvailabilityProvider: ExpressAvailabilityProvider

    // MARK: Published property

    @Published var alert: AlertBinder?

    @Published private(set) var viewState: ActionButtonState = .initial

    @Published private var isOpeningRequired = false

    // MARK: Public property

    let model: ActionButtonModel

    // MARK: Private property

    private weak var coordinator: ActionButtonsSwapFlowRoutable?
    private weak var tokensOrderProvider: (any MainScreenUIOrderedTokensProviding)?
    private var uiOrderedWalletModels: [any WalletModel]?
    private var bag: Set<AnyCancellable> = []

    private let lastButtonTapped: PassthroughSubject<ActionButtonModel, Never>
    private let userWalletModel: UserWalletModel

    init(
        model: ActionButtonModel,
        coordinator: some ActionButtonsSwapFlowRoutable,
        lastButtonTapped: PassthroughSubject<ActionButtonModel, Never>,
        userWalletModel: some UserWalletModel,
        tokensOrderProvider: (any MainScreenUIOrderedTokensProviding)?
    ) {
        self.model = model
        self.coordinator = coordinator
        self.lastButtonTapped = lastButtonTapped
        self.userWalletModel = userWalletModel
        self.tokensOrderProvider = tokensOrderProvider

        bind()
    }

    @MainActor
    func tap() {
        trackTapEvent()

        switch viewState {
        case .initial:
            handleInitialStateTap()
        case .loading, .disabled, .unavailable:
            break
        case .restricted(let reason):
            alert = .init(title: "", message: reason)
        case .idle:
            openSwap()
        }
    }

    @MainActor
    func updateState(to state: ActionButtonState) {
        viewState = state
    }
}

// MARK: - Bind

private extension SwapActionButtonViewModel {
    func bind() {
        lastButtonTapped
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { viewModel, model in
                if model != viewModel.model, viewModel.isOpeningRequired {
                    viewModel.isOpeningRequired = false
                }
            }
            .store(in: &bag)

        $viewState
            .receive(on: DispatchQueue.main)
            .withPrevious()
            .sink { [weak self] oldValue, newValue in
                guard let self else { return }

                guard newValue != .initial else {
                    isOpeningRequired = false
                    return
                }

                if oldValue == .loading {
                    scheduleLoadedAction()
                }
            }
            .store(in: &bag)

        tokensOrderProvider?
            .uiOrderedWalletModelsPublisher
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { viewModel, ordered in
                viewModel.uiOrderedWalletModels = ordered
            }
            .store(in: &bag)
    }
}

// MARK: Handle tap from initial state

@MainActor
private extension SwapActionButtonViewModel {
    func handleUpdatingStateTap() {
        updateState(to: .loading)
        isOpeningRequired = true
        lastButtonTapped.send(model)
    }

    func handleUpdatedStateTap() {
        updateState(to: .idle)
        tap()
    }

    func handleFailedStateTap(reason: String) {
        updateState(to: .restricted(reason: reason))
        tap()
    }

    func handleInitialStateTap() {
        isOpeningRequired = false

        let expressAvailabilityUpdateState = expressAvailabilityProvider.expressAvailabilityUpdateStateValue
        let hasCache = expressAvailabilityProvider.hasCache

        switch (expressAvailabilityUpdateState, hasCache) {
        case (_, true):
            handleUpdatedStateTap()
        case (.updating, false):
            handleUpdatingStateTap()
        case (.updated, false):
            handleUpdatedStateTap()
        case (.failed(let error), false):
            handleFailedStateTap(reason: error.localizedDescription)
        }
    }
}

// MARK: Handle loading completion

private extension SwapActionButtonViewModel {
    func scheduleLoadedAction() {
        switch viewState {
        case .restricted(let reason): showScheduledAlert(with: reason)
        case .idle: scheduledOpenSwap()
        case .loading, .initial, .disabled, .unavailable: break
        }
    }

    func scheduledOpenSwap() {
        guard isOpeningRequired else { return }

        openSwap()
        isOpeningRequired = false
    }

    func openSwap() {
        let helper = SwapPredefinedParametersHelper()
        let orderedWalletModels = uiOrderedWalletModels
            ?? AccountWalletModelsAggregator.walletModels(from: userWalletModel.accountModelsManager)

        if let parameters = helper.makeParameters(
            origin: .mainScreen(.init(orderedWalletModels: orderedWalletModels)),
            userWalletInfo: userWalletModel.userWalletInfo
        ) {
            coordinator?.openSwap(predefinedParameters: parameters)
        } else {
            let tokenSelectorViewModel = TokenSelectorViewModel(walletsProvider: .common(), availabilityProvider: .swap())
            coordinator?.openSwap(userWalletModel: userWalletModel, tokenSelectorViewModel: tokenSelectorViewModel)
        }
    }

    func showScheduledAlert(with message: String) {
        guard isOpeningRequired else { return }

        isOpeningRequired = false
        alert = .init(title: "", message: message)
    }
}
