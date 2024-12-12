//
//  SellActionButtonViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import Foundation

final class SellActionButtonViewModel: ActionButtonViewModel {
    // MARK: Dependencies

    @Injected(\.exchangeService)
    private var exchangeService: CombinedExchangeService

    // MARK: Published properties

    @Published var alert: AlertBinder?

    @Published private(set) var viewState: ActionButtonState = .initial {
        didSet {
            guard viewState != .initial else {
                isOpeningRequired = false
                return
            }

            if oldValue == .loading {
                scheduleLoadedAction()
            }
        }
    }

    @Published private var isOpeningRequired = false

    // MARK: Public property

    let model: ActionButtonModel

    // MARK: Private property

    private weak var coordinator: ActionButtonsSellFlowRoutable?
    private var bag: Set<AnyCancellable> = []
    private var exchangeServiceState: ExchangeServiceState = .initializing

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

        exchangeService
            .sellInitializationPublisher
            .withWeakCaptureOf(self)
            .sink { viewModel, state in
                viewModel.exchangeServiceState = state
            }
            .store(in: &bag)
    }

    @MainActor
    func tap() {
        trackTapEvent()

        switch viewState {
        case .initial:
            handleInitialStateTap()
        case .loading, .disabled:
            break
        case .restricted(let reason):
            alert = .init(title: "", message: reason)
        case .idle:
            guard !isOpeningRequired else { return }

            coordinator?.openSell(userWalletModel: userWalletModel)
        }
    }

    @MainActor
    func updateState(to state: ActionButtonState) {
        viewState = state
    }

    @MainActor
    private func handleInitialStateTap() {
        switch exchangeServiceState {
        case .initializing: handleInitializingStateTap()
        case .initialized: handleInitializedStateTap()
        case .failed(let error): handleFailedStateTap(reason: error.localizedDescription)
        }
    }
}

// MARK: Handle tap from initial state

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
}

// MARK: Handle loading completion

private extension SellActionButtonViewModel {
    func scheduleLoadedAction() {
        switch viewState {
        case .restricted(let reason): showScheduledAlert(with: reason)
        case .idle: scheduledOpenSell()
        case .loading, .initial, .disabled: break
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
