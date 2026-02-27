//
//  MobileCreateWalletCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemUIUtils

class MobileCreateWalletCoordinator: CoordinatorObject {
    let navigationRouter: NavigationRouter
    let dismissAction: Action<OutputOptions>
    let popToRootAction: Action<PopToRootOptions>

    @Published private(set) var rootViewModel: MobileCreateWalletViewModel?

    required init(
        navigationRouter: NavigationRouter,
        dismissAction: @escaping Action<OutputOptions>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.navigationRouter = navigationRouter
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: InputOptions) {
        rootViewModel = MobileCreateWalletViewModel(source: options.source, coordinator: self, delegate: self)
    }
}

// MARK: - MobileCreateWalletRoutable

extension MobileCreateWalletCoordinator: MobileCreateWalletRoutable {
    func openMobileOnboarding(input: MobileOnboardingInput) {
        openOnboarding(inputOptions: .mobileInput(input, navigationRouter))
    }

    func closeMobileCreateWallet() {
        dismiss(with: .dismiss)
    }
}

// MARK: - MobileCreateWalletDelegate

extension MobileCreateWalletCoordinator: MobileCreateWalletDelegate {
    func onCreateWallet(userWalletModel: UserWalletModel) {
        openMain(userWalletModel: userWalletModel)
    }
}

// MARK: - Navigation

private extension MobileCreateWalletCoordinator {
    func openOnboarding(inputOptions: OnboardingCoordinator.Options) {
        let dismissAction: Action<OnboardingCoordinator.OutputOptions> = { [weak self] options in
            switch options {
            case .main(let userWalletModel):
                self?.openMain(userWalletModel: userWalletModel)
            case .dismiss:
                self?.navigationRouter.pop()
            }
        }

        let coordinator = OnboardingCoordinator(dismissAction: dismissAction)
        coordinator.start(with: inputOptions)

        navigationRouter.push(route: coordinator)
    }

    func openMain(userWalletModel: UserWalletModel) {
        dismiss(with: .main(userWalletModel: userWalletModel))
    }
}

// MARK: - Options

extension MobileCreateWalletCoordinator {
    struct InputOptions {
        let source: MobileCreateWalletSource
    }

    enum OutputOptions {
        case main(userWalletModel: UserWalletModel)
        case dismiss
    }
}
