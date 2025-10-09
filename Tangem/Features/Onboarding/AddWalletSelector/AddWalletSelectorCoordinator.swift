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

    @Published private(set) var rootViewModel: AddWalletSelectorViewModel?

    // MARK: - Child coordinators

    @Published var hardwareCreateWalletCoordinator: HardwareCreateWalletCoordinator?
    @Published var mobileCreateWalletCoordinator: MobileCreateWalletCoordinator?

    required init(
        dismissAction: @escaping Action<OutputOptions>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: InputOptions) {
        rootViewModel = AddWalletSelectorViewModel(coordinator: self)
    }
}

// MARK: - AddWalletSelectorRoutable

extension AddWalletSelectorCoordinator: AddWalletSelectorRoutable {
    func openAddHardwareWallet() {
        let dismissAction: Action<HardwareCreateWalletCoordinator.OutputOptions> = { [weak self] options in
            switch options {
            case .main(let userWalletModel):
                self?.openMain(userWalletModel: userWalletModel)
            }
        }

        let coordinator = HardwareCreateWalletCoordinator(dismissAction: dismissAction)
        coordinator.start(with: HardwareCreateWalletCoordinator.InputOptions())
        hardwareCreateWalletCoordinator = coordinator
    }

    func openAddMobileWallet() {
        let dismissAction: Action<MobileCreateWalletCoordinator.OutputOptions> = { [weak self] options in
            switch options {
            case .main(let userWalletModel):
                self?.openMain(userWalletModel: userWalletModel)
            }
        }

        let coordinator = MobileCreateWalletCoordinator(dismissAction: dismissAction)
        coordinator.start(with: MobileCreateWalletCoordinator.InputOptions())
        mobileCreateWalletCoordinator = coordinator
    }
}

// MARK: - Navigation

private extension AddWalletSelectorCoordinator {
    func openMain(userWalletModel: UserWalletModel) {
        dismiss(with: .main(userWalletModel: userWalletModel))
    }
}

// MARK: - Options

extension AddWalletSelectorCoordinator {
    struct InputOptions {}

    enum OutputOptions {
        case main(userWalletModel: UserWalletModel)
    }
}
