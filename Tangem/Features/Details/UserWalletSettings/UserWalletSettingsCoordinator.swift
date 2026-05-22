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
    @Published var hardwareBackupTypesCoordinator: HardwareBackupTypesCoordinator?
    @Published var notificationSettingsCoordinator: NotificationSettingsCoordinator?

    // MARK: - Child view models

    @Published var mobileBackupTypesViewModel: MobileBackupTypesViewModel?
    @Published var accountFormViewModel: AccountFormViewModel?
    @Published var mobileRemoveWalletViewModel: MobileRemoveWalletViewModel?

    // MARK: - Helpers

    @Published var modalOnboardingCoordinatorKeeper: Bool = false

    private let isPresentedSubject = CurrentValueSubject<Bool, Never>(false)
    private var accountPendingNavigationSteps: [AccountPendingNavigationStep] = []
    private var accountPendingNavigationStepsProcessingSubscription: AnyCancellable?

    required init(
        dismissAction: @escaping Action<OutputOptions>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    deinit {
        assert(
            accountPendingNavigationSteps.isEmpty,
            "There are pending navigation steps that were not processed. Update/fix the pending steps display mechanism"
        )
    }

    func start(with userWalletModel: InputOptions) {
        rootViewModel = UserWalletSettingsViewModel(userWalletModel: userWalletModel, coordinator: self)
        bind()
    }

    func onViewAppear() {
        isPresentedSubject.send(true)
    }

    func onViewDisappear() {
        isPresentedSubject.send(false)
    }

    /// Unfortunately, we can't just observe `accountFormViewModel` to process pending navigation steps when
    /// account form is dismissed, because it becomes `nil` earlier than actual dismissal happens.
    /// Therefore this method should be called on every account form dismissal.
    func onAccountFormDismiss() {
        processAccountPendingNavigationSteps(isPresented: isPresentedSubject.value)
    }

    private func bind() {
        accountPendingNavigationStepsProcessingSubscription = isPresentedSubject
            .withWeakCaptureOf(self)
            .sink { coordinator, isPresented in
                coordinator.processAccountPendingNavigationSteps(isPresented: isPresented)
            }
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

extension UserWalletSettingsCoordinator: UserWalletSettingsRoutable {
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

    /// Implementation for `UserWalletSettingsRoutable` interface.
    func openManageTokens(
        walletModelsManager: WalletModelsManager,
        userTokensManager: UserTokensManager,
        userWalletConfig: UserWalletConfig
    ) {
        let context = LegacyManageTokensContext(
            userTokensManager: userTokensManager,
            walletModelsManager: walletModelsManager
        )

        openManageTokens(
            context: context,
            userWalletConfig: userWalletConfig,
            analyticsSourceRawValue: Analytics.ParameterValue.walletSettings.rawValue
        ) { [weak self] _ in
            self?.manageTokensCoordinator = nil
        }
    }

    func openNotificationSettings(userWalletModel: UserWalletModel) {
        let dismissAction: Action<Void> = { [weak self] _ in
            self?.notificationSettingsCoordinator = nil
        }

        let coordinator = NotificationSettingsCoordinator(
            dismissAction: dismissAction,
            popToRootAction: popToRootAction
        )
        coordinator.start(with: userWalletModel)
        notificationSettingsCoordinator = coordinator
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

    func openMobileRemoveWalletNotification(userWalletModel: UserWalletModel) {
        let viewModel = MobileRemoveWalletNotificationViewModel(userWalletModel: userWalletModel, coordinator: self)

        Task { @MainActor in
            floatingSheetPresenter.enqueue(sheet: viewModel)
        }
    }

    func openAppSettings() {
        UIApplication.openSystemSettings()
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

    /// Unfortunately, we can't just observe `rootViewModel.alert` to process pending navigation steps when alert is dismissed,
    /// because it becomes `nil` earlier than actual alert dismissal happens. Therefore this method should be called on
    /// every alert dismissal in the root view model.
    func onAlertDismiss() {
        processAccountPendingNavigationSteps(isPresented: isPresentedSubject.value)
    }
}

// MARK: - TransactionNotificationsRowToggleRoutable

extension UserWalletSettingsCoordinator: TransactionNotificationsRowToggleRoutable {
    func openTransactionNotifications() {
        let transactionNotificationsModalViewModel = TransactionNotificationsModalViewModel(coordinator: self)

        Task { @MainActor in
            floatingSheetPresenter.enqueue(sheet: transactionNotificationsModalViewModel)
        }
    }
}

// MARK: - TransactionNotificationsModalRoutable

extension UserWalletSettingsCoordinator: TransactionNotificationsModalRoutable {
    func dismissTransactionNotifications() {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
        }
    }
}

// MARK: - UserSettingsAccountsRoutable

extension UserWalletSettingsCoordinator: UserSettingsAccountsRoutable {
    func addNewAccount(accountModelsManager: any AccountModelsManager, userWalletConfig: UserWalletConfig) {
        accountFormViewModel = AccountFormViewModel(
            accountModelsManager: accountModelsManager,
            // Mikhail Andreev - in future we will support multiple types of accounts and their creation process
            // will vary
            flowType: .create(.crypto),
            closeAction: { [weak self] result, createdAccount in
                guard let self else {
                    return
                }

                rootViewModel?.accountsViewModel?.handleAccountOperationResult(result)
                rootViewModel?.accountsViewModel?.handleCreatedAccount(createdAccount)
                accountFormViewModel = nil
            }
        )
    }

    /// Implementation for `UserSettingsAccountsRoutable` interface.
    func openManageTokens(
        accountModelsManager: any AccountModelsManager,
        cryptoAccountModel: any CryptoAccountModel,
        userWalletConfig: UserWalletConfig
    ) {
        accountPendingNavigationSteps.append(
            .manageTokens(
                accountModelsManager: accountModelsManager,
                cryptoAccountModel: cryptoAccountModel,
                userWalletConfig: userWalletConfig
            )
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
                self?.rootViewModel?.accountsViewModel?.handleAccountOperationResult(result)
                self?.archivedAccountsCoordinator = nil
            },
            popToRootAction: popToRootAction
        )

        coordinator.start(with: ArchivedAccountsCoordinator.Options(accountModelsManager: accountModelsManager))

        archivedAccountsCoordinator = coordinator
    }

    func handleAccountsLimitReached() {
        rootViewModel?.handleAccountsLimitReached()
    }

    func handleAccountsRedistribution(sourceAccountName: String, targetAccountName: String) {
        accountPendingNavigationSteps.append(
            .tokensRedistribution(sourceAccountName: sourceAccountName, targetAccountName: targetAccountName)
        )
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

// MARK: - MobileRemoveWalletDelegate

extension UserWalletSettingsCoordinator: MobileRemoveWalletDelegate {
    func didRemoveMobileWallet() {
        dismiss()
    }
}

// MARK: - Navigation helpers and convenience methods

private extension UserWalletSettingsCoordinator {
    func processAccountPendingNavigationSteps(isPresented: Bool) {
        func canProcessPendingStep() -> Bool {
            // Any presented alert and/or accounts-related modal sheets (`accountFormViewModel`) or pushed screens
            // (`archivedAccountsCoordinator`) might interfere with the pending navigation step handling
            isPresented
                && rootViewModel?.alert == nil
                && accountFormViewModel == nil
                && archivedAccountsCoordinator == nil
        }

        guard
            accountPendingNavigationSteps.isNotEmpty,
            canProcessPendingStep()
        else {
            return
        }

        defer {
            accountPendingNavigationSteps.removeFirst()
        }

        let step = accountPendingNavigationSteps[0]

        switch step {
        case .tokensRedistribution(let sourceAccountName, let targetAccountName):
            rootViewModel?.handleAccountsRedistribution(
                sourceAccountName: sourceAccountName,
                targetAccountName: targetAccountName
            )
        case .manageTokens(let accountModelsManager, let cryptoAccountModel, let userWalletConfig):
            let manageTokensContext = CommonManageTokensContext(
                accountModelsManager: accountModelsManager,
                currentAccount: cryptoAccountModel
            )
            openManageTokens(
                context: manageTokensContext,
                userWalletConfig: userWalletConfig,
                analyticsSourceRawValue: Analytics.ParameterValue.accountSourceNew.rawValue
            ) { [weak self] _ in
                self?.manageTokensCoordinator = nil
            }
        }
    }

    /// Helper method for both legacy and accounts-aware environments.
    func openManageTokens(
        context: ManageTokensContext,
        userWalletConfig: UserWalletConfig,
        analyticsSourceRawValue: String,
        dismissAction: @escaping Action<Void>
    ) {
        let coordinator = ManageTokensCoordinator(
            dismissAction: dismissAction,
            popToRootAction: popToRootAction
        )

        coordinator.start(
            with: ManageTokensCoordinator.Options(
                context: context,
                userWalletConfig: userWalletConfig,
                analyticsSourceRawValue: analyticsSourceRawValue
            )
        )

        manageTokensCoordinator = coordinator
    }

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

    func openMain(userWalletModel: UserWalletModel) {
        dismiss(with: .main(userWalletModel: userWalletModel))
    }
}

// MARK: - Auxiliary types

private extension UserWalletSettingsCoordinator {
    /// Represents optional navigation steps that could be performed after account creation/unarchiving.
    enum AccountPendingNavigationStep {
        case tokensRedistribution(
            sourceAccountName: String,
            targetAccountName: String
        )

        case manageTokens(
            accountModelsManager: any AccountModelsManager,
            cryptoAccountModel: any CryptoAccountModel,
            userWalletConfig: UserWalletConfig
        )
    }
}
