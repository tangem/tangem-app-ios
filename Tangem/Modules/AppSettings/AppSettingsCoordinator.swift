//
//  AppSettingsCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Combine
import Foundation

class AppSettingsCoordinator: CoordinatorObject {
    var dismissAction: Action
    var popToRootAction: ParamsAction<PopToRootOptions>

    // MARK: - Main view model

    @Published private(set) var rootViewModel: AppSettingsViewModel?

    required init(
        dismissAction: @escaping Action,
        popToRootAction: @escaping ParamsAction<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        rootViewModel = AppSettingsViewModel(coordinator: self)
    }
}

// MARK: - Options

extension AppSettingsCoordinator {
    enum Options {
        case `default`
    }
}

// MARK: - AppSettingsRoutable

extension AppSettingsCoordinator: AppSettingsRoutable {
    func openTokenSynchronization() {}
    func openResetSavedCards() {}
}
