//
//  UserWalletSettingsCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import UIKit
import Foundation
import Combine
import TangemFoundation
import struct TangemUIUtils.AlertBinder

class UserWalletSettingsCoordinator: CoordinatorObject {
    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Injected

    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: any FloatingSheetPresenter

    // MARK: - Root view model

    @Published private(set) var rootViewModel: UserWalletSettingsViewModel?

    // MARK: - Child coordinators

    @Published var modalOnboardingCoordinator: OnboardingCoordinator?
    @Published var referralCoordinator: ReferralCoordinator?
    @Published var manageTokensCoordinator: ManageTokensCoordinator?
    @Published var scanCardSettingsCoordinator: ScanCardSettingsCoordinator?

    // MARK: - Child view models

    @Published var mobileBackupTypesViewModel: MobileBackupTypesViewModel?

    // MARK: - Helpers

    @Published var modalOnboardingCoordinatorKeeper: Bool = false

    required init(
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with userWalletModel: Options) {
        rootViewModel = UserWalletSettingsViewModel(userWalletModel: userWalletModel, coordinator: self)
    }
}

// MARK: - Options

extension UserWalletSettingsCoordinator {
    typealias Options = UserWalletModel
}

// MARK: - UserWalletSettingsRoutable

extension UserWalletSettingsCoordinator:
    UserWalletSettingsRoutable,
    TransactionNotificationsModalRoutable,
    MobileBackupNeededRoutable,
    MobileBackupTypesRoutable {
    func openAddNewAccount() {
        // [REDACTED_TODO_COMMENT]
    }

    func openOnboardingModal(with options: OnboardingCoordinator.Options) {
        let dismissAction: Action<OnboardingCoordinator.OutputOptions> = { [weak self] result in
            self?.modalOnboardingCoordinator = nil
            if result.isSuccessful {
                self?.dismiss()
            }
        }

        let coordinator = OnboardingCoordinator(dismissAction: dismissAction)
        coordinator.start(with: options)
        modalOnboardingCoordinator = coordinator
    }

    func openScanCardSettings(with input: ScanCardSettingsViewModel.Input) {
        let coordinator = ScanCardSettingsCoordinator(dismissAction: dismissAction, popToRootAction: popToRootAction)
        coordinator.start(with: .init(input: input))
        scanCardSettingsCoordinator = coordinator
    }

    func openReferral(input: ReferralInputModel) {
        let dismissAction: Action<Void> = { [weak self] _ in
            self?.referralCoordinator = nil
        }

        let coordinator = ReferralCoordinator(dismissAction: dismissAction)
        coordinator.start(with: .init(input: input))
        referralCoordinator = coordinator
        Analytics.log(.referralScreenOpened)
    }

    func openManageTokens(userWalletModel: any UserWalletModel) {
        let dismissAction: Action<Void> = { [weak self] _ in
            self?.manageTokensCoordinator = nil
        }

        let coordinator = ManageTokensCoordinator(dismissAction: dismissAction)
        coordinator.start(with: .init(userWalletModel: userWalletModel))
        manageTokensCoordinator = coordinator
    }

    func openTransactionNotifications() {
        let transactionNotificationsModalViewModel = TransactionNotificationsModalViewModel(coordinator: self)

        Task { @MainActor in
            floatingSheetPresenter.enqueue(sheet: transactionNotificationsModalViewModel)
        }
    }

    func openMobileBackupNeeded(userWalletModel: UserWalletModel) {
        Analytics.log(.walletSettingsNoticeBackupFirst)

        let viewModel = MobileBackupNeededViewModel(userWalletModel: userWalletModel, routable: self)

        Task { @MainActor in
            floatingSheetPresenter.enqueue(sheet: viewModel)
        }
    }

    func openMobileBackupTypes(userWalletModel: UserWalletModel) {
        Analytics.log(.backupStarted)

        mobileBackupTypesViewModel = MobileBackupTypesViewModel(userWalletModel: userWalletModel, routable: self)
    }

    func openAppSettings() {
        UIApplication.openSystemSettings()
    }

    func dismiss() {
        if userWalletRepository.models.isEmpty {
            // fix stories animation no-resume issue
            DispatchQueue.main.async {
                self.popToRoot()
            }
        } else {
            dismissAction(())
        }
    }

    // MARK: - TransactionNotificationsModalRoutable

    func dismissTransactionNotifications() {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
        }
    }

    // MARK: - MobileBackupOnboardingRoutable

    func openMobileBackupOnboarding(userWalletModel: UserWalletModel) {
        let backupInput = MobileOnboardingInput(flow: .walletActivate(userWalletModel: userWalletModel))
        openOnboardingModal(with: .mobileInput(backupInput))
    }

    // MARK: - MobileBackupNeededRoutable

    func dismissMobileBackupNeeded() {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
        }
    }

    func openMobileOnboarding(input: MobileOnboardingInput) {
        openOnboardingModal(with: .mobileInput(input))
    }

    // MARK: - MobileBackupTypesRoutable

    func openOnboarding(input: MobileOnboardingInput) {
        openOnboardingModal(with: .mobileInput(input))
    }
}
