//
//  OrganizeTokensCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

final class OrganizeTokensCoordinator: CoordinatorObject {
    let dismissAction: Action
    let popToRootAction: ParamsAction<PopToRootOptions>

    // MARK: - Root view model

    @Published private(set) var rootViewModel: OrganizeTokensViewModel?

    required init(
        dismissAction: @escaping Action,
        popToRootAction: @escaping ParamsAction<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        let userWalletModel = options.userWalletModel
        let userTokenListManager = userWalletModel.userTokenListManager
        let optionsManager = OrganizeTokensOptionsManager(
            userTokenListManager: userTokenListManager,
            editingThrottleInterval: 1.0
        )
        let walletModelsAdapter = OrganizeWalletModelsAdapter(
            userTokenListManager: userTokenListManager,
            organizeTokensOptionsProviding: optionsManager,
            organizeTokensOptionsEditing: optionsManager
        )

        rootViewModel = OrganizeTokensViewModel(
            coordinator: self,
            walletModelsManager: userWalletModel.walletModelsManager,
            walletModelsAdapter: walletModelsAdapter,
            organizeTokensOptionsProviding: optionsManager,
            organizeTokensOptionsEditing: optionsManager
        )
    }
}

// MARK: - Options

extension OrganizeTokensCoordinator {
    struct Options {
        let userWalletModel: UserWalletModel
    }
}

// MARK: - OrganizeTokensRoutable protocol conformance

extension OrganizeTokensCoordinator: OrganizeTokensRoutable {
    func didTapCancelButton() {
        dismiss()
    }
}
