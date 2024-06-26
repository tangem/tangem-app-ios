//
//  ManageTokensCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine

class ManageTokensCoordinator: CoordinatorObject {
    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    @Published var rootViewModel: ManageTokensViewModel? = nil

    @Published var addCustomTokenCoordinator: AddCustomTokenCoordinator? = nil

    private var selectedUserWalletModel: UserWalletModel?

    required init(
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        selectedUserWalletModel = options.userWalletModel
        let userWalletModel = options.userWalletModel
        let config = userWalletModel.config
        let adapter = ManageTokensAdapter(settings: .init(
            longHashesSupported: config.hasFeature(.longHashes),
            existingCurves: config.existingCurves,
            supportedBlockchains: Set(config.supportedBlockchains),
            userTokensManager: userWalletModel.userTokensManager
        ))

        rootViewModel = .init(
            adapter: adapter,
            userTokensManager: userWalletModel.userTokensManager,
            walletModelsManager: userWalletModel.walletModelsManager,
            coordinator: self
        )
    }
}

extension ManageTokensCoordinator {
    struct Options {
        let userWalletModel: UserWalletModel
    }
}

extension ManageTokensCoordinator: ManageTokensRoutable {
    func openAddCustomToken() {
        guard let selectedUserWalletModel else {
            return
        }

        let dismissAction: Action<Void> = { [weak self] _ in
            self?.addCustomTokenCoordinator = nil
        }

        let addCustomTokenCoordinator = AddCustomTokenCoordinator(dismissAction: dismissAction)
        addCustomTokenCoordinator.start(with: .init(userWalletModel: selectedUserWalletModel))

        self.addCustomTokenCoordinator = addCustomTokenCoordinator
    }
}
