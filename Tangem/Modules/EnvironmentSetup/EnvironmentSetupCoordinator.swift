//
//  EnvironmentSetupCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class EnvironmentSetupCoordinator: CoordinatorObject {
    let dismissAction: Action
    let popToRootAction: ParamsAction<PopToRootOptions>

    // MARK: - Root view model

    @Published private(set) var rootViewModel: EnvironmentSetupViewModel?

    // MARK: - Child view models

    @Published var supportedBlockchainsPreferencesViewModel: SupportedBlockchainsPreferencesViewModel?

    required init(
        dismissAction: @escaping Action,
        popToRootAction: @escaping ParamsAction<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        rootViewModel = .init(coordinator: self)
    }
}

// MARK: - Options

extension EnvironmentSetupCoordinator {
    struct Options {}
}

// MARK: - EnvironmentSetupRoutable

extension EnvironmentSetupCoordinator: EnvironmentSetupRoutable {
    func openSupportedBlockchainsPreferences() {
        supportedBlockchainsPreferencesViewModel = SupportedBlockchainsPreferencesViewModel()
    }
}
