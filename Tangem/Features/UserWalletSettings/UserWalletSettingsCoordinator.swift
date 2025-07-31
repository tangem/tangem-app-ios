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

    @Published var hotBackupTypesViewModel: HotBackupTypesViewModel?

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
    HotBackupNeededRoutable,
    HotBackupTypesRoutable {
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

    func openHotBackupNeeded(userWalletModel: UserWalletModel) {
        let viewModel = HotBackupNeededViewModel(userWalletModel: userWalletModel, routable: self)

        Task { @MainActor in
            floatingSheetPresenter.enqueue(sheet: viewModel)
        }
    }

    func openHotBackupTypes(userWalletModel: UserWalletModel) {
        hotBackupTypesViewModel = HotBackupTypesViewModel(userWalletModel: userWalletModel, routable: self)
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

    // MARK: - HotBackupOnboardingRoutable

    func openHotBackupOnboarding(userWalletModel: UserWalletModel) {
        let backupInput = HotOnboardingInput(flow: .walletActivate(userWalletModel: userWalletModel))
        openOnboardingModal(with: .hotInput(backupInput))
    }

    // MARK: - HotBackupNeededRoutable

    func dismissHotBackupNeeded() {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
        }
    }

    // MARK: - HotBackupTypesRoutable

    func openHotBackupRevealSeedPhrase(userWalletModel: UserWalletModel) {
        runTask(in: self) { coordinator in
            let settingsUtil = HotSettingsUtil(userWalletModel: userWalletModel)
            let state = await settingsUtil.calculateSeedPhraseState()

            switch state {
            case .onboarding(let needsValidation):
                coordinator.openHotOnboardingModal(
                    userWalletModel: userWalletModel,
                    needAccessCodeValidation: needsValidation
                )
            }
        }
    }

    func openHotBackupOnboardingSeedPhrase(userWalletModel: UserWalletModel) {
        let backupInput = HotOnboardingInput(flow: .seedPhraseBackup(userWalletModel: userWalletModel))
        openOnboardingModal(with: .hotInput(backupInput))
    }

    func openHotOnboardingModal(userWalletModel: UserWalletModel, needAccessCodeValidation: Bool) {
        let backupInput = HotOnboardingInput(flow: .seedPhraseReveal(
            userWalletModel: userWalletModel,
            needAccessCodeValidation: needAccessCodeValidation
        ))
        openOnboardingModal(with: .hotInput(backupInput))
    }
}
