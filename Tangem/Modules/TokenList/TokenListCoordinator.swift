//
//  TokenListCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

class TokenListCoordinator: CoordinatorObject {
    var dismissAction: Action
    var popToRootAction: ParamsAction<PopToRootOptions>

    // MARK: - Main view model

    @Published private(set) var tokenListViewModel: TokenListViewModel? = nil

    // MARK: - Child view models

    @Published var addCustomTokenViewModel: AddCustomTokenViewModel? = nil

    required init(dismissAction: @escaping Action, popToRootAction: @escaping ParamsAction<PopToRootOptions>) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with mode: TokenListViewModel.Mode) {
        tokenListViewModel = .init(mode: mode, coordinator: self)
    }
}

extension TokenListCoordinator: AddCustomTokenRoutable {
    func closeModule() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { // fix freeze ios13
            self.dismiss()
        }
    }
}

extension TokenListCoordinator: TokenListRoutable {
    func openAddCustom(for cardModel: CardViewModel) {
        addCustomTokenViewModel = .init(cardModel: cardModel, coordinator: self)
    }
}
