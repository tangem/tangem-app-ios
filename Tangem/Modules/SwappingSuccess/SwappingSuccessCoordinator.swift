//
//  SwappingSuccessCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class SwappingSuccessCoordinator: CoordinatorObject {
    let dismissAction: Action
    let popToRootAction: ParamsAction<PopToRootOptions>

    // MARK: - Root view model

    @Published private(set) var rootViewModel: SwappingSuccessViewModel?

    // MARK: - Child view models

    @Published var webViewContainerViewModel: WebViewContainerViewModel?

    private let factory: SwappingDependenciesFactoring

    required init(
        factory: SwappingDependenciesFactoring,
        dismissAction: @escaping Action,
        popToRootAction: @escaping ParamsAction<PopToRootOptions>
    ) {
        self.factory = factory
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        rootViewModel = SwappingSuccessViewModel(
            inputModel: options.inputModel,
            userWalletModel: factory.userWalletModel(),
            currencyMapper: factory.currencyMapper(),
            blockchainNetwork: factory.walletModel().blockchainNetwork,
            coordinator: self
        )
    }
}

// MARK: - Options

extension SwappingSuccessCoordinator {
    struct Options {
        let inputModel: SwappingSuccessInputModel
    }
}

// MARK: - SwappingSuccessRoutable

extension SwappingSuccessCoordinator: SwappingSuccessRoutable {
    func didTapCloseButton() {
        dismiss()
    }

    func openExplorer(url: URL?, currencyName: String) {
        webViewContainerViewModel = WebViewContainerViewModel(
            url: url,
            title: Localization.commonExplorerFormat(currencyName),
            withCloseButton: true
        )
    }
}
