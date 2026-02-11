//
//  SellActionButtonViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import struct TangemUIUtils.AlertBinder

final class SellActionButtonViewModel: ActionButtonViewModel {
    // MARK: Dependencies

    @Injected(\.sellService)
    private var sellService: SellService

    // MARK: Published properties

    @Published var alert: AlertBinder?

    @Published private(set) var viewState: ActionButtonState = .initial

    @Published private var isOpeningRequired = false

    // MARK: Public property

    let model: ActionButtonModel

    // MARK: Private property

    private weak var coordinator: ActionButtonsSellFlowRoutable?
    private var bag: Set<AnyCancellable> = []
    private var sellServiceState: SellServiceState = .initializing

    private let lastButtonTapped: PassthroughSubject<ActionButtonModel, Never>
    private let userWalletModel: UserWalletModel

    init(
        model: ActionButtonModel,
        coordinator: some ActionButtonsSellFlowRoutable,
        lastButtonTapped: PassthroughSubject<ActionButtonModel, Never>,
        userWalletModel: some UserWalletModel
    ) {
        self.model = model
        self.coordinator = coordinator
        self.lastButtonTapped = lastButtonTapped
        self.userWalletModel = userWalletModel

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
        case .idle where FeatureProvider.isAvailable(.accounts):
            let tokenSelectorViewModel = AccountsAwareTokenSelectorViewModel(walletsProvider: .common(), availabilityProvider: .sell())
            coordinator?.openSell(userWalletModel: userWalletModel, tokenSelectorViewModel: tokenSelectorViewModel)
        case .idle:
            coordinator?.openSell(userWalletModel: userWalletModel)
        }
    }

    @MainActor
    func updateState(to state: ActionButtonState) {
        viewState = state
    }
}

// MARK: Handle state

@MainActor
private extension SellActionButtonViewModel {
    func handleInitializingStateTap() {
        updateState(to: .loading)
        isOpeningRequired = true
        lastButtonTapped.send(model)
    }

    func handleInitializedStateTap() {
        updateState(to: .idle)
        tap()
    }

    func handleFailedStateTap(reason: String) {
        updateState(to: .restricted(reason: reason))
        tap()
    }

    private func handleInitialStateTap() {
        switch sellServiceState {
        case .initializing: handleInitializingStateTap()
        case .initialized: handleInitializedStateTap()
        case .failed(let error): handleFailedStateTap(reason: error.localizedDescription)
        }
    }
}

// MARK: Bind

private extension SellActionButtonViewModel {
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

        sellService
            .initializationPublisher
            .withWeakCaptureOf(self)
            .sink { viewModel, state in
                viewModel.sellServiceState = state
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
    }
}

// MARK: Handle loading completion

private extension SellActionButtonViewModel {
    func scheduleLoadedAction() {
        switch viewState {
        case .restricted(let reason): showScheduledAlert(with: reason)
        case .idle: scheduledOpenSell()
        case .loading, .initial, .disabled, .unavailable: break
        }
    }

    func scheduledOpenSell() {
        guard isOpeningRequired else { return }

        coordinator?.openSell(userWalletModel: userWalletModel)
        isOpeningRequired = false
    }

    func showScheduledAlert(with message: String) {
        guard isOpeningRequired else { return }

        alert = .init(title: "", message: message)
        isOpeningRequired = false
    }
}
