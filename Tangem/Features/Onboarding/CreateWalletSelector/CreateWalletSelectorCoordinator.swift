//
//  CreateWalletSelectorCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import TangemUIUtils

class CreateWalletSelectorCoordinator: CoordinatorObject {
    private let navigationRouter: NavigationRouter
    let dismissAction: Action<OutputOptions>
    let popToRootAction: Action<PopToRootOptions>

    @Published private(set) var rootViewModel: CreateWalletSelectorViewModel?
    @Published private(set) var rootPromoViewModel: CreateWalletSelectorPromoViewModel?
    @Published var onboardingCoordinator: OnboardingCoordinator?
    @Published var mobileCreateWalletCoordinator: MobileCreateWalletCoordinator?

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
        if AppSettings.shared.shouldShowMobilePromoWalletSelector {
            rootPromoViewModel = CreateWalletSelectorPromoViewModel(coordinator: self)
        } else {
            rootViewModel = CreateWalletSelectorViewModel(coordinator: self)
        }
    }
}

// MARK: - CreateNewWalletSelectorRoutable

extension CreateWalletSelectorCoordinator: CreateWalletSelectorRoutable {
    func openOnboarding(options: OnboardingCoordinator.Options) {
        openOnboarding(inputOptions: options)
    }

    func openMain(userWalletModel: UserWalletModel) {
        dismiss(with: .main(userWalletModel: userWalletModel))
    }

    func openCreateMobileWallet() {
        let dismissAction: Action<MobileCreateWalletCoordinator.OutputOptions> = { [weak self] options in
            switch options {
            case .main(let userWalletModel):
                self?.openMain(userWalletModel: userWalletModel)
            case .dismiss:
                self?.navigationRouter.pop()
            }
        }

        let coordinator = MobileCreateWalletCoordinator(
            navigationRouter: navigationRouter,
            dismissAction: dismissAction,
            popToRootAction: popToRootAction
        )
        coordinator.start(with: MobileCreateWalletCoordinator.InputOptions(source: .createWalletIntro))
        navigationRouter.push(route: coordinator)
    }

    func closeCreateWalletSelector() {
        dismiss(with: .dismiss)
    }
}

// MARK: - MobileCreateWalletRoutable

extension CreateWalletSelectorCoordinator: MobileCreateWalletRoutable {
    func openMobileOnboarding(input: MobileOnboardingInput) {
        openOnboarding(inputOptions: .mobileInput(input, nil))
    }

    func closeMobileCreateWallet() {
        navigationRouter.pop()
    }
}

// MARK: - MobileCreateWalletDelegate

extension CreateWalletSelectorCoordinator: MobileCreateWalletDelegate {
    func onCreateWallet(userWalletModel: UserWalletModel) {
        openMain(userWalletModel: userWalletModel)
    }
}

// MARK: - Navigation

private extension CreateWalletSelectorCoordinator {
    func openOnboarding(inputOptions: OnboardingCoordinator.Options) {
        let dismissAction: Action<OnboardingCoordinator.OutputOptions> = { [weak self] options in
            switch options {
            case .main(let userWalletModel):
                self?.openMain(userWalletModel: userWalletModel)
            case .dismiss:
                self?.onboardingCoordinator = nil
            }
        }

        let coordinator = OnboardingCoordinator(dismissAction: dismissAction)
        coordinator.start(with: inputOptions)
        onboardingCoordinator = coordinator
    }
}

// MARK: - Options

extension CreateWalletSelectorCoordinator {
    struct InputOptions {}

    enum OutputOptions {
        case main(userWalletModel: UserWalletModel)
        case dismiss
    }
}
