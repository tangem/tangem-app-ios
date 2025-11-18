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

    private var options: Options?
    private let analyticsSourceRawValue = Analytics.ParameterValue.settings.rawValue

    required init(
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        self.options = options

        let analyticsParams: [Analytics.ParameterKey: String] = [.source: analyticsSourceRawValue]
        Analytics.log(event: .manageTokensScreenOpened, params: analyticsParams)

        let config = options.userWalletConfig
        let adapter = ManageTokensAdapter(
            settings: .init(
                longHashesSupported: config.hasFeature(.longHashes),
                existingCurves: config.existingCurves,
                supportedBlockchains: Set(config.supportedBlockchains),
                userTokensManager: options.userTokensManager,
                analyticsSourceRawValue: analyticsSourceRawValue
            )
        )

        rootViewModel = .init(
            adapter: adapter,
            userTokensManager: options.userTokensManager,
            walletModelsManager: options.walletModelsManager,
            coordinator: self
        )
    }
}

extension ManageTokensCoordinator {
    struct Options {
        let walletModelsManager: WalletModelsManager
        let userTokensManager: UserTokensManager
        let userWalletConfig: UserWalletConfig
    }
}

extension ManageTokensCoordinator: ManageTokensRoutable {
    func openAddCustomToken() {
        guard let options else {
            return
        }

        let dismissAction: Action<Void> = { [weak self] _ in
            self?.addCustomTokenCoordinator = nil
        }

        let analyticsParams: [Analytics.ParameterKey: String] = [.source: analyticsSourceRawValue]
        Analytics.log(event: .manageTokensButtonCustomToken, params: analyticsParams)

        let addCustomTokenCoordinator = AddCustomTokenCoordinator(dismissAction: dismissAction)
        addCustomTokenCoordinator.start(
            with: .init(
                userWalletConfig: options.userWalletConfig,
                userTokensManager: options.userTokensManager,
                analyticsSourceRawValue: analyticsSourceRawValue
            )
        )

        self.addCustomTokenCoordinator = addCustomTokenCoordinator
    }
}
