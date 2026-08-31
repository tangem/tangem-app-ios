//
//  MobileBackupTypesCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemMobileWalletBackup

class MobileBackupTypesCoordinator: CoordinatorObject {
    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: any FloatingSheetPresenter

    let dismissAction: Action<OutputOptions>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Root view model

    @Published private(set) var rootViewModel: MobileBackupTypesViewModel?

    // MARK: - Child coordinators

    @Published var modalOnboardingCoordinator: OnboardingCoordinator?
    @Published var hardwareBackupTypesCoordinator: HardwareBackupTypesCoordinator?

    // MARK: - Helpers

    @Published var modalOnboardingCoordinatorKeeper: Bool = false

    required init(
        dismissAction: @escaping Action<OutputOptions>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: InputOptions) {
        rootViewModel = MobileBackupTypesViewModel(
            userWalletModel: options.userWalletModel,
            mode: options.mode,
            coordinator: self
        )
    }
}

// MARK: - MobileBackupTypesRoutable

extension MobileBackupTypesCoordinator: MobileBackupTypesRoutable {
    func openMobileUpgrade(userWalletModel: UserWalletModel) {
        let dismissAction: Action<HardwareBackupTypesCoordinator.OutputOptions> = { [weak self] options in
            switch options {
            case .main(let userWalletModel):
                self?.openMain(userWalletModel: userWalletModel)
            }
        }

        let inputOptions = HardwareBackupTypesCoordinator.InputOptions(userWalletModel: userWalletModel)
        let coordinator = HardwareBackupTypesCoordinator(dismissAction: dismissAction)
        coordinator.start(with: inputOptions)
        hardwareBackupTypesCoordinator = coordinator
    }

    func openMobileOnboarding(input: MobileOnboardingInput) {
        openOnboardingModal(with: .mobileInput(input))
    }

    func openMobileBackupICloudDetails(
        backup: MobileWalletBackup,
        userWalletModel: UserWalletModel,
        onDelete: @escaping () -> Void
    ) {
        let viewModel = MobileBackupICloudDetailsViewModel(
            backup: backup,
            userWalletModel: userWalletModel,
            coordinator: self,
            onDelete: onDelete
        )

        floatingSheetPresenter.enqueue(sheet: viewModel)
    }

    func openMobileBackupICloudStorageUnavailable(input: MobileBackupStorageUnavailableInput, output: MobileBackupStorageUnavailableOutput) {
        let viewModel = MobileBackupStorageUnavailableViewModel(input: input, output: output, coordinator: self)
        floatingSheetPresenter.enqueue(sheet: viewModel)
    }

    func openMobileBackupICloudNotFound(output: MobileBackupNotFoundOutput) {
        let viewModel = MobileBackupNotFoundViewModel(output: output, coordinator: self)
        floatingSheetPresenter.enqueue(sheet: viewModel)
    }
}

// MARK: - MobileBackupStorageUnavailableRoutable

extension MobileBackupTypesCoordinator: MobileBackupStorageUnavailableRoutable {
    func closeMobileBackupStorageUnavailable() {
        floatingSheetPresenter.removeActiveSheet()
    }
}

// MARK: - MobileBackupNotFoundRoutable

extension MobileBackupTypesCoordinator: MobileBackupNotFoundRoutable {
    func closeMobileBackupNotFound() {
        floatingSheetPresenter.removeActiveSheet()
    }
}

// MARK: - MobileBackupICloudDetailsRoutable

extension MobileBackupTypesCoordinator: MobileBackupICloudDetailsRoutable {
    func closeMobileBackupICloudDetails() {
        floatingSheetPresenter.removeActiveSheet()
    }
}

// MARK: - Navigation

private extension MobileBackupTypesCoordinator {
    func openOnboardingModal(with options: OnboardingCoordinator.Options) {
        let dismissAction: Action<OnboardingCoordinator.OutputOptions> = { [weak self] options in
            self?.modalOnboardingCoordinator = nil

            switch options {
            case .main(let userWalletModel):
                self?.dismiss(with: .main(userWalletModel: userWalletModel))
            case .dismiss:
                break
            }
        }

        let coordinator = OnboardingCoordinator(dismissAction: dismissAction)
        coordinator.start(with: options)
        modalOnboardingCoordinator = coordinator
    }

    func openMain(userWalletModel: UserWalletModel) {
        dismiss(with: .main(userWalletModel: userWalletModel))
    }
}

// MARK: - Options

extension MobileBackupTypesCoordinator {
    struct InputOptions {
        let userWalletModel: UserWalletModel
        let mode: MobileBackupTypesMode
    }

    enum OutputOptions {
        case main(userWalletModel: UserWalletModel)
    }
}
