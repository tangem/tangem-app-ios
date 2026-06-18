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
    private var bag: Set<AnyCancellable> = []

    private let lastButtonTapped: PassthroughSubject<ActionButtonModel, Never>
    private let userWalletModel: UserWalletModel

    init(
        model: ActionButtonModel,
        coordinator: some ActionButtonsSwapFlowRoutable,
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
        case .loading, .disabled, .unavailable, .restricted:
            break
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
        showRestrictionReason()
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
        let userWalletInfo = userWalletModel.userWalletInfo

        // Opening the swap flow only picks a source to spend; topping up a card-linked wallet is
        // blocked later, when its token is chosen as the swap destination.
        let walletModels = AccountWalletModelsAggregator.walletModels(from: userWalletModel.accountModelsManager)

        let bestEffort = MainSwapPairResolver.makeBestEffortSourceToken(from: walletModels, userWalletInfo: userWalletInfo)
        let fallback = walletModels.first.map { walletModel in
            CommonSendSwapableTokenFactory(
                userWalletInfo: userWalletInfo,
                walletModel: walletModel,
                operationType: .swap
            ).makeSwapableToken()
        }

        guard let sourceToken = bestEffort ?? fallback else {
            return
        }

        let resolver = MainSwapPairResolver(
            userWalletModel: userWalletModel,
            swapAvailabilityChecker: CommonSwapAvailabilityChecker(userWalletInfo: userWalletInfo)
        )

        coordinator?.openSwap(predefinedParameters: .deferredPairResolution(source: sourceToken, resolver: resolver))
    }

    func showScheduledAlert(with message: String) {
        guard isOpeningRequired else { return }

        isOpeningRequired = false
        alert = .init(title: "", message: message)
    }
}
