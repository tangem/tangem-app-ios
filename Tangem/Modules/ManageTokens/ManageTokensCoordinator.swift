//
//  ManageTokensCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

class ManageTokensCoordinator: CoordinatorObject {
    var dismissAction: Action<Void>
    var popToRootAction: Action<PopToRootOptions>

    // MARK: - Published

    @Published private(set) var manageTokensViewModel: ManageTokensViewModel? = nil

    // MARK: - Child ViewModels

    @Published var addCustomTokenViewModel: LegacyAddCustomTokenViewModel? = nil

    // MARK: - Init

    required init(dismissAction: @escaping Action<Void>, popToRootAction: @escaping Action<PopToRootOptions>) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    // MARK: - Implmentation

    func start(with options: ManageTokensCoordinator.Options) {
        manageTokensViewModel = .init(
            settings: options.settings,
            userTokensManager: options.userTokensManager,
            tokenQuotesRepository: options.tokenQuotesRepository,
            coordinator: self
        )
    }
}

extension ManageTokensCoordinator {
    struct Options {
        let settings: LegacyManageTokensSettings
        let userTokensManager: UserTokensManager
        let tokenQuotesRepository: TokenQuotesRepository
    }
}

extension ManageTokensCoordinator: ManageTokensRoutable {
    func openInfoTokenModule() {}

    func openAddTokenModule() {}

    func openEditTokenModule() {}

    func openAddCustomTokenModule(settings: LegacyManageTokensSettings, userTokensManager: UserTokensManager) {
        addCustomTokenViewModel = .init(
            settings: settings,
            userTokensManager: userTokensManager,
            coordinator: self
        )
    }
}

// MARK: - LegacyAddCustomTokenRoutable

extension ManageTokensCoordinator: LegacyAddCustomTokenRoutable {
    func closeModule() {
        dismiss()
    }
}
