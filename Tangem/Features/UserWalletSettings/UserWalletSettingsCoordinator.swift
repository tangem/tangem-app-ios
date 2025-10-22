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
import TangemMobileWalletSdk
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
    @Published var mobileUpgradeCoordinator: MobileUpgradeCoordinator?
    @Published var accountDetailsCoordinator: AccountDetailsCoordinator?
    @Published var archivedAccountsCoordinator: ArchivedAccountsCoordinator?

    // MARK: - Child view models

    @Published var mobileBackupTypesViewModel: MobileBackupTypesViewModel?
    @Published var mailViewModel: MailViewModel?
    @Published var accountFormViewModel: AccountFormViewModel?

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
    func addNewAccount(accountModelsManager: any AccountModelsManager) {
        accountFormViewModel = AccountFormViewModel(
            accountModelsManager: accountModelsManager,
            // Mikhail Andreev - in future we will support multiple types of accounts and their creation process
            // will vary
            flowType: .create(.crypto),
            closeAction: { [weak self] in
                self?.accountFormViewModel = nil
            }
        )
    }

    func openAccountDetails(account: any BaseAccountModel, accountModelsManager: AccountModelsManager, userWalletConfig: UserWalletConfig) {
        let coordinator = AccountDetailsCoordinator(
            dismissAction: { [weak self] in
                self?.accountDetailsCoordinator = nil
            },
            popToRootAction: popToRootAction
        )

        coordinator.start(
            with: AccountDetailsCoordinator.Options(
                account: account,
                userWalletConfig: userWalletConfig,
                accountModelsManager: accountModelsManager
            )
        )

        accountDetailsCoordinator = coordinator
    }

    func openArchivedAccounts(accountModelsManager: any AccountModelsManager) {
        let coordinator = ArchivedAccountsCoordinator(
            dismissAction: { [weak self] in
                self?.archivedAccountsCoordinator = nil
            },
            popToRootAction: popToRootAction
        )

        coordinator.start(with: ArchivedAccountsCoordinator.Options(accountModelsManager: accountModelsManager))

        archivedAccountsCoordinator = coordinator
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

    func openManageTokens(
        walletModelsManager: WalletModelsManager,
        userTokensManager: UserTokensManager,
        userWalletConfig: UserWalletConfig
    ) {
        let dismissAction: Action<Void> = { [weak self] _ in
            self?.manageTokensCoordinator = nil
        }

        let coordinator = ManageTokensCoordinator(dismissAction: dismissAction)
        coordinator.start(
            with: .init(
                walletModelsManager: walletModelsManager,
                userTokensManager: userTokensManager,
                userWalletConfig: userWalletConfig
            )
        )
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

    func openMobileUpgrade(userWalletModel: UserWalletModel, context: MobileWalletContext) {
        Task { @MainActor in
            let dismissAction: Action<MobileUpgradeCoordinator.OutputOptions> = { [weak self] options in
                switch options {
                case .dismiss:
                    self?.mobileUpgradeCoordinator = nil
                case .finish:
                    self?.mobileUpgradeCoordinator = nil
                    self?.mobileBackupTypesViewModel = nil
                }
            }

            let coordinator = MobileUpgradeCoordinator(dismissAction: dismissAction)
            let inputOptions = MobileUpgradeCoordinator.InputOptions(userWalletModel: userWalletModel, context: context)
            coordinator.start(with: inputOptions)
            mobileUpgradeCoordinator = coordinator
        }
    }
}
