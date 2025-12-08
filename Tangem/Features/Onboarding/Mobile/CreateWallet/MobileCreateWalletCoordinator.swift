//
//  MobileCreateWalletCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

class MobileCreateWalletCoordinator: CoordinatorObject {
    let dismissAction: Action<OutputOptions>
    let popToRootAction: Action<PopToRootOptions>

    @Published private(set) var rootViewModel: MobileCreateWalletViewModel?

    // MARK: - Child coordinators

    @Published var onboardingCoordinator: OnboardingCoordinator?

    required init(
        dismissAction: @escaping Action<OutputOptions>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: InputOptions) {
        rootViewModel = MobileCreateWalletViewModel(source: options.source, coordinator: self, delegate: self)
    }
}

// MARK: - MobileCreateWalletRoutable

extension MobileCreateWalletCoordinator: MobileCreateWalletRoutable {
    func openOnboarding(options: OnboardingCoordinator.Options) {
        openOnboarding(inputOptions: options)
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
                self?.onboardingCoordinator = nil
            }
        }

        let coordinator = OnboardingCoordinator(dismissAction: dismissAction)
        coordinator.start(with: inputOptions)
        onboardingCoordinator = coordinator
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
