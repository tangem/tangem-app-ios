//
//  LegacyTokenListCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

class LegacyTokenListCoordinator: CoordinatorObject {
    var dismissAction: Action
    var popToRootAction: ParamsAction<PopToRootOptions>

    // MARK: - Main view model

    @Published private(set) var tokenListViewModel: LegacyTokenListViewModel? = nil

    // MARK: - Child view models

    @Published var addCustomTokenViewModel: LegacyAddCustomTokenViewModel? = nil

    required init(dismissAction: @escaping Action, popToRootAction: @escaping ParamsAction<PopToRootOptions>) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with mode: LegacyTokenListViewModel.Mode) {
        tokenListViewModel = .init(mode: mode, coordinator: self)
    }
}

extension LegacyTokenListCoordinator: LegacyAddCustomTokenRoutable {
    func closeModule() {
        dismiss()
    }
}

extension LegacyTokenListCoordinator: LegacyTokenListRoutable {
    func openAddCustom(settings: LegacyManageTokensSettings, userTokensManager: UserTokensManager) {
        addCustomTokenViewModel = .init(
            settings: settings,
            userTokensManager: userTokensManager,
            coordinator: self
        )
    }
}
