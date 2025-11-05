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

final class UserWalletSettingsCoordinator: CoordinatorObject {
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
    @Published var accountDetailsCoordinator: AccountDetailsCoordinator?
    @Published var archivedAccountsCoordinator: ArchivedAccountsCoordinator?
    @Published var mobileBackupTypesCoordinator: MobileBackupTypesCoordinator?
    @Published var hardwareBackupTypesCoordinator: HardwareBackupTypesCoordinator?

    // MARK: - Child view models

    @Published var mobileBackupTypesViewModel: MobileBackupTypesViewModel?
    @Published var accountFormViewModel: AccountFormViewModel?
    @Published var mobileRemoveWalletViewModel: MobileRemoveWalletViewModel?

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
    TransactionNotificationsModalRoutable {
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
        let context = LegacyManageTokensContext(
            userTokensManager: userTokensManager,
            walletModelsManager: walletModelsManager
        )

        coordinator.start(
            with: .init(
                context: context,
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

        let viewModel = MobileBackupNeededViewModel(userWalletModel: userWalletModel, coordinator: self)

        Task { @MainActor in
            floatingSheetPresenter.enqueue(sheet: viewModel)
        }
    }

    func openMobileBackupTypes(userWalletModel: UserWalletModel) {
        let dismissAction: Action<Void> = { [weak self] _ in
            self?.mobileBackupTypesCoordinator = nil
        }

        let inputOptions = MobileBackupTypesCoordinator.InputOptions(userWalletModel: userWalletModel)
        let coordinator = MobileBackupTypesCoordinator(dismissAction: dismissAction)
        coordinator.start(with: inputOptions)
        mobileBackupTypesCoordinator = coordinator
    }

    func openMobileUpgrade(userWalletModel: UserWalletModel) {
        let dismissAction: Action<Void> = { [weak self] _ in
            self?.hardwareBackupTypesCoordinator = nil
            self?.dismiss()
        }

        let inputOptions = HardwareBackupTypesCoordinator.InputOptions(userWalletModel: userWalletModel)
        let coordinator = HardwareBackupTypesCoordinator(dismissAction: dismissAction)
        coordinator.start(with: inputOptions)
        hardwareBackupTypesCoordinator = coordinator
    }

    func openMobileOnboarding(input: MobileOnboardingInput) {
        openOnboardingModal(with: .mobileInput(input))
    }

    func openMobileRemoveWalletNotification(userWalletModel: UserWalletModel) {
        let viewModel = MobileRemoveWalletNotificationViewModel(userWalletModel: userWalletModel, coordinator: self)

        Task { @MainActor in
            floatingSheetPresenter.enqueue(sheet: viewModel)
        }
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
}

// MARK: - MobileBackupNeededRoutable

extension UserWalletSettingsCoordinator: MobileBackupNeededRoutable {
    func openMobileOnboardingFromMobileBackupNeeded(input: MobileOnboardingInput) {
        dismissMobileBackupNeeded()
        openOnboardingModal(with: .mobileInput(input))
    }

    func dismissMobileBackupNeeded() {
        floatingSheetPresenter.removeActiveSheet()
    }
}

// MARK: - MobileRemoveWalletNotificationRoutable

extension UserWalletSettingsCoordinator: MobileRemoveWalletNotificationRoutable {
    func openMobileRemoveWallet(userWalletId: UserWalletId) {
        dismissMobileRemoveWalletNotification()
        mobileRemoveWalletViewModel = MobileRemoveWalletViewModel(userWalletId: userWalletId, delegate: self)
    }

    func openMobileOnboardingFromRemoveWalletNotification(input: MobileOnboardingInput) {
        dismissMobileRemoveWalletNotification()
        openOnboardingModal(with: .mobileInput(input))
    }

    func dismissMobileRemoveWalletNotification() {
        floatingSheetPresenter.removeActiveSheet()
    }
}

// MARK: - MobileRemoveWalletDelegate

extension UserWalletSettingsCoordinator: MobileRemoveWalletDelegate {
    func didRemoveMobileWallet() {
        dismiss()
    }
}
