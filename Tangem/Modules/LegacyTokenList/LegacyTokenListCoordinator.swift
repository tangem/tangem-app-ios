//
//  LegacyTokenListCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

class LegacyTokenListCoordinator: CoordinatorObject {
    var dismissAction: Action<Void>
    var popToRootAction: Action<PopToRootOptions>

    // MARK: - Main view model

    @Published private(set) var tokenListViewModel: LegacyTokenListViewModel? = nil

    // MARK: - Child view models

    @Published var addCustomTokenViewModel: LegacyAddCustomTokenViewModel? = nil

    #warning("[REDACTED_TODO_COMMENT]")
    @Published var addCustomTokenCoordinator: AddCustomTokenCoordinator? = nil

    required init(dismissAction: @escaping Action<Void>, popToRootAction: @escaping Action<PopToRootOptions>) {
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
        #warning("[REDACTED_TODO_COMMENT]")
        let dismissAction: Action<Void> = { [weak self] _ in
            self?.addCustomTokenCoordinator = nil
        }

        let coordinator = AddCustomTokenCoordinator(dismissAction: dismissAction, popToRootAction: popToRootAction)
        addCustomTokenCoordinator = coordinator
        coordinator.start(with: AddCustomTokenCoordinator.Options(settings: settings, userTokensManager: userTokensManager))
    }
}
