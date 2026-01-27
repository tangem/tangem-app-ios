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
    // MARK: Published property

    @Published var alert: AlertBinder?

    @Published private(set) var viewState: ActionButtonState = .idle

    // MARK: Public property

    let model: ActionButtonModel

    // MARK: Private property

    private weak var coordinator: ActionButtonsSwapFlowRoutable?

    private let userWalletModel: UserWalletModel

    init(
        model: ActionButtonModel,
        coordinator: some ActionButtonsSwapFlowRoutable,
        lastButtonTapped: PassthroughSubject<ActionButtonModel, Never>,
        userWalletModel: some UserWalletModel
    ) {
        self.model = model
        self.coordinator = coordinator
        self.userWalletModel = userWalletModel
    }

    @MainActor
    func tap() {
        trackTapEvent()

        switch viewState {
        case .initial, .loading, .disabled, .unavailable:
            break
        case .restricted(let reason):
            alert = .init(title: "", message: reason)
        case .idle where FeatureProvider.isAvailable(.accounts):
            let tokenSelectorViewModel = AccountsAwareTokenSelectorViewModel(walletsProvider: .common(), availabilityProvider: .swap())
            coordinator?.openSwap(userWalletModel: userWalletModel, tokenSelectorViewModel: tokenSelectorViewModel)
        case .idle:
            coordinator?.openSwap(userWalletModel: userWalletModel)
        }
    }

    @MainActor
    func updateState(to state: ActionButtonState) {
        viewState = state
    }
}
