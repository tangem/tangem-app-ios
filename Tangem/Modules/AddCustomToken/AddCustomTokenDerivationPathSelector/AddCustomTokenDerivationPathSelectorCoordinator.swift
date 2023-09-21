//
//  AddCustomTokenDerivationPathSelectorCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSdk

class AddCustomTokenDerivationPathSelectorCoordinator: CoordinatorObject {
    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Root view model

    @Published private(set) var rootViewModel: AddCustomTokenDerivationPathSelectorViewModel?

    // MARK: - Child coordinators

    // MARK: - Child view models

    required init(
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        rootViewModel = AddCustomTokenDerivationPathSelectorViewModel(
            selectedDerivationOption: options.selectedDerivationOption,
            defaultDerivationPath: options.defaultDerivationPath,
            blockchainDerivationOptions: options.blockchainDerivationOptions,
            coordinator: self
        )
    }
}

// MARK: - Options

extension AddCustomTokenDerivationPathSelectorCoordinator {
    struct Options {
        let selectedDerivationOption: AddCustomTokenDerivationOption
        let defaultDerivationPath: DerivationPath
        let blockchainDerivationOptions: [AddCustomTokenDerivationOption]
    }
}

// MARK: - AddCustomTokenDerivationPathSelectorRoutable

extension AddCustomTokenDerivationPathSelectorCoordinator: AddCustomTokenDerivationPathSelectorRoutable {}
