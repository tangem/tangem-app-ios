//
//  JointAccountManagementCoordinator.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

final class JointAccountManagementCoordinator: CoordinatorObject {
    // MARK: - Navigation actions

    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Root view model

    @Published private(set) var rootViewModel: JointAccountOnboardingViewModel?

    init(
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        rootViewModel = JointAccountOnboardingViewModel(coordinator: self)
    }
}

// MARK: - Options

extension JointAccountManagementCoordinator {
    struct Options {
        let accountModelsManager: any AccountModelsManager
        let userWalletConfig: UserWalletConfig
    }
}

// MARK: - JointAccountOnboardingRoutable

extension JointAccountManagementCoordinator: JointAccountOnboardingRoutable {
    func closeOnboarding() {
        dismiss()
    }

    func continueOnboarding() {
        // [REDACTED_TODO_COMMENT]
    }
}
