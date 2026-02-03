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
import TangemLocalization
import struct TangemUIUtils.AlertBinder

final class UserWalletSettingsCoordinator: CoordinatorObject {
    let dismissAction: Action<OutputOptions>
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
    @Published var mobileUpgradeCoordinator: MobileUpgradeCoordinator?
    @Published var hardwareBackupTypesCoordinator: HardwareBackupTypesCoordinator?

    // MARK: - Child view models

    @Published var mobileBackupTypesViewModel: MobileBackupTypesViewModel?
    @Published var accountFormViewModel: AccountFormViewModel?
    @Published var mobileRemoveWalletViewModel: MobileRemoveWalletViewModel?

    // MARK: - Helpers

    @Published var modalOnboardingCoordinatorKeeper: Bool = false
    @Published var accountCreationFlowClosed: Bool = true

    var noActiveCreateOrArchiveAccountFlows: Bool {
        archivedAccountsCoordinator == nil && accountCreationFlowClosed
    }

    required init(
        dismissAction: @escaping Action<OutputOptions>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with userWalletModel: InputOptions) {
        rootViewModel = UserWalletSettingsViewModel(userWalletModel: userWalletModel, coordinator: self)
    }
}

// MARK: - Options

extension UserWalletSettingsCoordinator {
    typealias InputOptions = UserWalletModel

    enum OutputOptions {
        case main(userWalletModel: UserWalletModel)
        case dismiss
    }
}

// MARK: - UserWalletSettingsRoutable

extension UserWalletSettingsCoordinator:
    UserWalletSettingsRoutable,
    TransactionNotificationsModalRoutable {
    // MARK: UserWalletSettingsRoutable

    func openOnboardingModal(with options: OnboardingCoordinator.Options) {
        openOnboardingModal(options: options)
    }

    func openScanCardSettings(with input: ScanCardSettingsViewModel.Input) {
        let dismissAction: Action<Void> = { [weak self] _ in
            self?.dismiss(with: .dismiss)
        }

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
                userWalletConfig: userWalletConfig,
                analyticsSourceRawValue: Analytics.ParameterValue.walletSettings.rawValue
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

    func openMobileBackupNeeded(
        userWalletModel: UserWalletModel,
        source: MobileOnboardingFlowSource,
        onBackupFinished: @escaping () -> Void
    ) {
        let viewModel = MobileBackupNeededViewModel(
            userWalletModel: userWalletModel,
            source: source,
            onBackupFinished: onBackupFinished,
            coordinator: self
        )

        Task { @MainActor in
            floatingSheetPresenter.enqueue(sheet: viewModel)
        }
    }

    func openMobileBackupTypes(userWalletModel: UserWalletModel) {
        let dismissAction: Action<MobileBackupTypesCoordinator.OutputOptions> = { [weak self] options in
            switch options {
            case .main(let userWalletModel):
                self?.dismiss(with: .main(userWalletModel: userWalletModel))
            }
        }

        let inputOptions = MobileBackupTypesCoordinator.InputOptions(userWalletModel: userWalletModel, mode: .backup)
        let coordinator = MobileBackupTypesCoordinator(dismissAction: dismissAction)
        coordinator.start(with: inputOptions)
        mobileBackupTypesCoordinator = coordinator
    }

    @MainActor
    func openHardwareBackupTypes(userWalletModel: UserWalletModel) {
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

    @MainActor
    func openMobileUpgradeToHardwareWallet(userWalletModel: UserWalletModel, context: MobileWalletContext) {
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

    @MainActor
    func openMobileBackupToUpgradeNeeded(onBackupRequested: @escaping () -> Void) {
        let sheet = MobileBackupToUpgradeNeededViewModel(coordinator: self, onBackup: onBackupRequested)
        floatingSheetPresenter.enqueue(sheet: sheet)
    }

    func openMobileOnboarding(input: MobileOnboardingInput) {
        openOnboardingModal(options: .mobileInput(input))
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

    func openMain(userWalletModel: UserWalletModel) {
        dismiss(with: .main(userWalletModel: userWalletModel))
    }

    @MainActor
    func closeOnboarding() {
        modalOnboardingCoordinator = nil
    }

    func dismiss() {
        if userWalletRepository.models.isEmpty {
            // fix stories animation no-resume issue
            DispatchQueue.main.async {
                self.popToRoot()
            }
        } else {
            dismiss(with: .dismiss)
        }
    }

    // MARK: TransactionNotificationsModalRoutable

    func dismissTransactionNotifications() {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
        }
    }

    // MARK: UserSettingsAccountsRoutable

    func addNewAccount(accountModelsManager: any AccountModelsManager) {
        accountCreationFlowClosed = false

        accountFormViewModel = AccountFormViewModel(
            accountModelsManager: accountModelsManager,
            // Mikhail Andreev - in future we will support multiple types of accounts and their creation process
            // will vary
            flowType: .create(.crypto),
            closeAction: { [weak self] result in
                self?.accountFormViewModel = nil
                self?.rootViewModel?.handleAccountOperationResult(result)
            }
        )
    }

    func openAccountDetails(account: any BaseAccountModel, accountModelsManager: any AccountModelsManager, userWalletConfig: UserWalletConfig) {
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
            dismissAction: { [weak self] result in
                self?.archivedAccountsCoordinator = nil
                self?.rootViewModel?.handleAccountOperationResult(result)
            },
            popToRootAction: popToRootAction
        )

        coordinator.start(with: ArchivedAccountsCoordinator.Options(accountModelsManager: accountModelsManager))

        archivedAccountsCoordinator = coordinator
    }

    func handleAccountsLimitReached() {
        rootViewModel?.handleAccountsLimitReached()
    }
}

// MARK: - MobileBackupNeededRoutable

extension UserWalletSettingsCoordinator: MobileBackupNeededRoutable {
    func openMobileOnboardingFromMobileBackupNeeded(input: MobileOnboardingInput, onBackupFinished: @escaping () -> Void) {
        dismissMobileBackupNeeded()
        openOnboardingModal(options: .mobileInput(input), onSuccess: onBackupFinished)
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
        openOnboardingModal(options: .mobileInput(input))
    }

    func dismissMobileRemoveWalletNotification() {
        floatingSheetPresenter.removeActiveSheet()
    }
}

// MARK: - MobileBackupToUpgradeNeededRoutable

extension UserWalletSettingsCoordinator: MobileBackupToUpgradeNeededRoutable {
    func dismissMobileBackupToUpgradeNeeded() {
        floatingSheetPresenter.removeActiveSheet()
    }
}

// MARK: - MobileRemoveWalletDelegate

extension UserWalletSettingsCoordinator: MobileRemoveWalletDelegate {
    func didRemoveMobileWallet() {
        dismiss()
    }
}

// MARK: - Navigation

private extension UserWalletSettingsCoordinator {
    func openOnboardingModal(options: OnboardingCoordinator.Options, onSuccess: (() -> Void)? = nil) {
        let dismissAction: Action<OnboardingCoordinator.OutputOptions> = { [weak self] result in
            self?.modalOnboardingCoordinator = nil
            if result.isSuccessful {
                onSuccess?()
            }
        }

        let coordinator = OnboardingCoordinator(dismissAction: dismissAction)
        coordinator.start(with: options)
        modalOnboardingCoordinator = coordinator
    }
}
