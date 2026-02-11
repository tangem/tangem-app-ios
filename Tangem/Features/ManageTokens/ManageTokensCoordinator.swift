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

    required init(
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        self.options = options

        let analyticsParams: [Analytics.ParameterKey: String] = [.source: options.analyticsSourceRawValue]
        Analytics.log(event: .manageTokensScreenOpened, params: analyticsParams)

        let config = options.userWalletConfig
        let context = options.context

        let adapter = ManageTokensAdapter(
            settings: .init(
                existingCurves: config.existingCurves,
                supportedBlockchains: Set(config.supportedBlockchains),
                hardwareLimitationUtil: HardwareLimitationsUtil(config: config),
                analyticsSourceRawValue: options.analyticsSourceRawValue,
                context: context
            )
        )

        rootViewModel = .init(
            adapter: adapter,
            context: context,
            coordinator: self
        )
    }
}

extension ManageTokensCoordinator {
    struct Options {
        let context: ManageTokensContext
        let userWalletConfig: UserWalletConfig
        let analyticsSourceRawValue: String
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

        let analyticsParams: [Analytics.ParameterKey: String] = [.source: options.analyticsSourceRawValue]
        Analytics.log(event: .manageTokensButtonCustomToken, params: analyticsParams)

        let addCustomTokenCoordinator = AddCustomTokenCoordinator(dismissAction: dismissAction)
        addCustomTokenCoordinator.start(
            with: .init(
                userWalletConfig: options.userWalletConfig,
                analyticsSourceRawValue: options.analyticsSourceRawValue,
                context: options.context
            )
        )

        self.addCustomTokenCoordinator = addCustomTokenCoordinator
    }
}
