//
//  SellActionButtonViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

final class SellActionButtonViewModel: ActionButtonViewModel {
    private(set) var presentationState: ActionButtonPresentationState = .initial

    let model: ActionButtonModel

    private let coordinator: ActionButtonsSellFlowRoutable
    private let userWalletModel: UserWalletModel

    init(
        model: ActionButtonModel,
        coordinator: some ActionButtonsSellFlowRoutable,
        userWalletModel: some UserWalletModel
    ) {
        self.model = model
        self.coordinator = coordinator
        self.userWalletModel = userWalletModel
    }

    @MainActor
    func tap() {
        switch presentationState {
        case .initial:
            updateState(to: .loading)
        case .loading:
            break
        case .idle:
            coordinator.openSell(userWalletModel: userWalletModel)
        }
    }

    @MainActor
    func updateState(to state: ActionButtonPresentationState) {
        presentationState = state
    }
}
