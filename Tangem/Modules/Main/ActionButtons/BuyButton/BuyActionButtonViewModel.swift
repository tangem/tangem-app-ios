//
//  BuyActionButtonViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import Foundation

final class BuyActionButtonViewModel: ActionButtonViewModel {
    // MARK: Published property

    @Published private(set) var viewState: ActionButtonState = .idle

    @Published var alert: AlertBinder? = nil

    // MARK: Public property

    let model: ActionButtonModel

    // MARK: Private property

    private weak var coordinator: ActionButtonsBuyFlowRoutable?
    private let lastButtonTapped: PassthroughSubject<ActionButtonModel, Never>
    private let userWalletModel: UserWalletModel

    init(
        model: ActionButtonModel,
        lastButtonTapped: PassthroughSubject<ActionButtonModel, Never>,
        coordinator: some ActionButtonsBuyFlowRoutable,
        userWalletModel: some UserWalletModel
    ) {
        self.model = model
        self.coordinator = coordinator
        self.lastButtonTapped = lastButtonTapped
        self.userWalletModel = userWalletModel
    }

    @MainActor
    func tap() {
        trackTapEvent()

        switch viewState {
        case .loading, .restricted, .initial:
            break
        case .idle:
            lastButtonTapped.send(model)
            coordinator?.openBuy(userWalletModel: userWalletModel)
        }
    }

    @MainActor
    func updateState(to state: ActionButtonState) {
        viewState = state
    }
}
