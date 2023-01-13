//
//  SuccessSwappingCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class SuccessSwappingCoordinator: CoordinatorObject, Identifiable {
    let id = UUID()
    let dismissAction: Action
    let popToRootAction: ParamsAction<PopToRootOptions>

    // MARK: - Root view model

    @Published private(set) var rootViewModel: SuccessSwappingViewModel?

    // MARK: - Child view models

    @Published var webViewContainerViewModel: WebViewContainerViewModel?

    required init(
        dismissAction: @escaping Action,
        popToRootAction: @escaping ParamsAction<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        rootViewModel = SuccessSwappingViewModel(
            inputModel: options.inputModel,
            coordinator: self
        )
    }
}

// MARK: - Options

extension SuccessSwappingCoordinator {
    struct Options {
        let inputModel: SuccessSwappingInputModel
    }
}

// MARK: - SuccessSwappingRoutable

extension SuccessSwappingCoordinator: SuccessSwappingRoutable {
    func didTapCloseButton() {
        dismiss()
    }

    func openExplorer(url: URL?, displayName: String) {
        webViewContainerViewModel = WebViewContainerViewModel(
            url: url,
            title: Localization.commonExplorerFormat(displayName),
            withCloseButton: true
        )
    }
}
