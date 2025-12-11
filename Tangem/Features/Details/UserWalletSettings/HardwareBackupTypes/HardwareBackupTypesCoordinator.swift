//
//  HardwareBackupTypesCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemMobileWalletSdk

class HardwareBackupTypesCoordinator: CoordinatorObject {
    let dismissAction: Action<OutputOptions>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Injected

    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: any FloatingSheetPresenter

    // MARK: - Root view model

    @Published private(set) var rootViewModel: HardwareBackupTypesViewModel?

    // MARK: - Child coordinators

    @Published var onboardingCoordinator: OnboardingCoordinator?
    @Published var hardwareCreateWalletCoordinator: HardwareCreateWalletCoordinator?
    @Published var mobileUpgradeCoordinator: MobileUpgradeCoordinator?

    // MARK: - Helpers

    @Published var modalKeeper: Bool = false

    required init(
        dismissAction: @escaping Action<OutputOptions>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: InputOptions) {
        rootViewModel = HardwareBackupTypesViewModel(userWalletModel: options.userWalletModel, coordinator: self)
    }
}

// MARK: - Internal methods

extension HardwareBackupTypesCoordinator {
    func onHardwareCreateWalletCloseTap() {
        hardwareCreateWalletCoordinator = nil
    }
}

// MARK: - HardwareBackupTypesRoutable

extension HardwareBackupTypesCoordinator: HardwareBackupTypesRoutable {
    func openCreateHardwareWallet(userWalletModel: UserWalletModel) {
        let dismissAction: Action<HardwareCreateWalletCoordinator.OutputOptions> = { [weak self] options in
            switch options {
            case .main(let userWalletModel):
                self?.dismiss(with: .main(userWalletModel: userWalletModel))
            }
        }

        let coordinator = HardwareCreateWalletCoordinator(dismissAction: dismissAction)
        coordinator.start(with: HardwareCreateWalletCoordinator.InputOptions(userWalletModel: userWalletModel, source: .hardwareWallet))
        hardwareCreateWalletCoordinator = coordinator
    }

    func openMobileOnboarding(input: MobileOnboardingInput) {
        openOnboarding(with: .mobileInput(input))
    }

    func openUpgradeToHardwareWallet(userWalletModel: UserWalletModel, context: MobileWalletContext) {
        let dismissAction: Action<MobileUpgradeCoordinator.OutputOptions> = { [weak self] options in
            switch options {
            case .dismiss:
                self?.mobileUpgradeCoordinator = nil
            case .main(let userWalletModel):
                self?.openMain(userWalletModel: userWalletModel)
            }
        }

        let coordinator = MobileUpgradeCoordinator(dismissAction: dismissAction)
        let inputOptions = MobileUpgradeCoordinator.InputOptions(userWalletModel: userWalletModel, context: context)
        coordinator.start(with: inputOptions)
        mobileUpgradeCoordinator = coordinator
    }

    func openMobileBackupToUpgradeNeeded(onBackupRequested: @escaping () -> Void) {
        let sheet = MobileBackupToUpgradeNeededViewModel(coordinator: self, onBackup: onBackupRequested)
        floatingSheetPresenter.enqueue(sheet: sheet)
    }

    func openMain(userWalletModel: UserWalletModel) {
        dismiss(with: .main(userWalletModel: userWalletModel))
    }

    func closeOnboarding() {
        onboardingCoordinator = nil
    }
}

// MARK: - MobileBackupToUpgradeNeededRoutable

extension HardwareBackupTypesCoordinator: MobileBackupToUpgradeNeededRoutable {
    func dismissMobileBackupToUpgradeNeeded() {
        floatingSheetPresenter.removeActiveSheet()
    }
}

// MARK: - Navigation

private extension HardwareBackupTypesCoordinator {
    func openOnboarding(with options: OnboardingCoordinator.Options) {
        let dismissAction: Action<OnboardingCoordinator.OutputOptions> = { [weak self] options in
            self?.onboardingCoordinator = nil

            switch options {
            case .main(let userWalletModel):
                self?.dismiss(with: .main(userWalletModel: userWalletModel))
            case .dismiss:
                break
            }
        }

        let coordinator = OnboardingCoordinator(dismissAction: dismissAction)
        coordinator.start(with: options)
        onboardingCoordinator = coordinator
    }
}

// MARK: - Options

extension HardwareBackupTypesCoordinator {
    struct InputOptions {
        let userWalletModel: UserWalletModel
    }

    enum OutputOptions {
        case main(userWalletModel: UserWalletModel)
    }
}
