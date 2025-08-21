//
//  CreateWalletSelectorCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import TangemLocalization
import TangemFoundation
import TangemUIUtils

class CreateWalletSelectorCoordinator: CoordinatorObject {
    let dismissAction: Action<OutputOptions>
    let popToRootAction: Action<PopToRootOptions>

    @Published private(set) var createViewModel: CreateWalletSelectorViewModel?
    @Published var onboardingCoordinator: OnboardingCoordinator?

    required init(
        dismissAction: @escaping Action<OutputOptions>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: InputOptions) {
        createViewModel = CreateWalletSelectorViewModel(coordinator: self)
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
    }
}
