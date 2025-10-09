//
//  AddWalletSelectorCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

class AddWalletSelectorCoordinator: CoordinatorObject {
    let dismissAction: Action<OutputOptions>
    let popToRootAction: Action<PopToRootOptions>

    @Published private(set) var viewModel: AddWalletSelectorViewModel?
    @Published var mobileCreateWalletCoordinator: MobileCreateWalletCoordinator?

    required init(
        dismissAction: @escaping Action<OutputOptions>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: InputOptions) {
        viewModel = AddWalletSelectorViewModel(coordinator: self)
    }
}

//// MARK: - CreateNewWalletSelectorRoutable
//
// extension CreateWalletSelectorCoordinator: CreateWalletSelectorRoutable {
//    func openMain(userWalletModel: UserWalletModel) {
//        dismiss(with: .main(userWalletModel: userWalletModel))
//    }
//
//    func openCreateMobileWallet() {
//        let dismissAction: Action<MobileCreateWalletCoordinator.OutputOptions> = { [weak self] options in
//            switch options {
//            case .main(let userWalletModel):
//                self?.openMain(userWalletModel: userWalletModel)
//            }
//        }
//
//        let coordinator = MobileCreateWalletCoordinator(dismissAction: dismissAction)
//        coordinator.start(with: MobileCreateWalletCoordinator.InputOptions())
//        mobileCreateWalletCoordinator = coordinator
//    }
// }

// MARK: - AddWalletSelectorRoutable

extension AddWalletSelectorCoordinator: AddWalletSelectorRoutable {
    func openAddHardwareWallet() {}

    func openAddMobileWallet() {}
}

//// MARK: - MobileCreateWalletDelegate
//
// extension CreateWalletSelectorCoordinator: MobileCreateWalletDelegate {
//    func onCreateWallet(userWalletModel: UserWalletModel) {
//        openMain(userWalletModel: userWalletModel)
//    }
// }

// MARK: - Navigation

private extension AddWalletSelectorCoordinator {
//    func openOnboarding(inputOptions: OnboardingCoordinator.Options) {
//        let dismissAction: Action<OnboardingCoordinator.OutputOptions> = { [weak self] options in
//            switch options {
//            case .main(let userWalletModel):
//                self?.openMain(userWalletModel: userWalletModel)
//            case .dismiss:
//                self?.onboardingCoordinator = nil
//            }
//        }
//
//        let coordinator = OnboardingCoordinator(dismissAction: dismissAction)
//        coordinator.start(with: inputOptions)
//        onboardingCoordinator = coordinator
//    }
}

// MARK: - Options

extension AddWalletSelectorCoordinator {
    struct InputOptions {}

    enum OutputOptions {
        case main(userWalletModel: UserWalletModel)
    }
}
