//
//  UserWalletSettingsViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import CombineExt
import TangemLocalization
import TangemFoundation
import TangemAccessibilityIdentifiers
import TangemMobileWalletSdk
import struct TangemUIUtils.AlertBinder
import struct TangemUIUtils.ConfirmationDialogViewModel
import TangemAssets

final class UserWalletSettingsViewModel: ObservableObject {
    // MARK: - Injected

    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.nftAvailabilityProvider) private var nftAvailabilityProvider: NFTAvailabilityProvider
    @Injected(\.userTokensPushNotificationsService) private var userTokensPushNotificationsService: UserTokensPushNotificationsService

    // MARK: - ViewState

    @Published private(set) var name: String
    @Published private(set) var walletImage: Image?

    @Published var accountsViewModel: UserSettingsAccountsViewModel?
    @Published var mobileUpgradeNotificationInput: NotificationViewInput? // [REDACTED_TODO_COMMENT]
    @Published var mobileAccessCodeViewModel: DefaultRowViewModel?
    @Published var backupViewModel: DefaultRowViewModel?

    var commonSectionModels: [DefaultRowViewModel] {
        [mobileBackupViewModel, manageTokensViewModel, cardSettingsViewModel, referralViewModel].compactMap { $0 }
    }

    var isMobileUpgradeAvailable: Bool {
        FeatureProvider.isAvailable(.mobileWallet) && userWalletModel.config.hasFeature(.userWalletUpgrade)
    }

    @Published var nftViewModel: DefaultToggleRowViewModel?
    @Published var pushNotificationsViewModel: TransactionNotificationsRowToggleViewModel?

    @Published var forgetViewModel: DefaultRowViewModel?

    @Published var alert: AlertBinder?
    @Published var forgetWalletConfirmationDialog: ConfirmationDialogViewModel?

    // MARK: - Private

    @Published private var mobileBackupViewModel: DefaultRowViewModel?
    @Published private var manageTokensViewModel: DefaultRowViewModel?
    @Published private var cardSettingsViewModel: DefaultRowViewModel?
    @Published private var referralViewModel: DefaultRowViewModel?

    /// Alert for account operations that needs to be shown after a modal sheet is dismissed.
    /// See `UserWalletSettingsCoordinatorView` for the trigger.
    private var accountsPendingAlert: AlertBinder?
    private let mobileSettingsUtil: MobileSettingsUtil

    private var isNFTEnabled: Bool {
        get { nftAvailabilityProvider.isNFTEnabled(for: userWalletModel) }
        set { nftAvailabilityProvider.setNFTEnabled(newValue, for: userWalletModel) }
    }

    private var analyticsContextParams: Analytics.ContextParams {
        .custom(userWalletModel.analyticsContextData)
    }

    private var currentWalletModelsManager: WalletModelsManager?
    private var currentUserTokensManager: UserTokensManager?

    // MARK: - Dependencies

    private let userWalletModel: UserWalletModel
    private weak var coordinator: UserWalletSettingsRoutable?
    private let dependencyUpdater: DependencyUpdater

    private var bag = Set<AnyCancellable>()

    init(
        userWalletModel: UserWalletModel,
        coordinator: UserWalletSettingsRoutable
    ) {
        name = userWalletModel.name
        mobileSettingsUtil = MobileSettingsUtil(userWalletModel: userWalletModel)

        self.userWalletModel = userWalletModel
        self.coordinator = coordinator

        dependencyUpdater = DependencyUpdater(userWalletModel: userWalletModel)
        dependencyUpdater.setup(owner: self)

        // Calling this setup method before `bind()` because we need to subscribe to accounts VM updates
        setupAccountsViewModel()
        bind()
    }

    deinit {
        assert(accountsPendingAlert == nil, "accountsPendingAlert was not shown before deallocation. Update the alert display mechanism.")
    }

    func onFirstAppear() {
        logScreenOpenedAnalytics()
    }

    func onAppear() {
        setupView()
        if FeatureProvider.isAvailable(.accounts) {
            loadWalletImage()
        }
    }

    func handleAccountOperationResult(_ result: AccountOperationResult) {
        switch result {
        case .none:
            return

        case .redistributionHappened(let pairs):
            // Find first actual redistribution between accounts and extract source account name
            // Skip external sources (legacy tokens from server) - they're initial placements, not redistributions
            // .lazy is used to avoid unnecessary iterations
            // Source - https://stackoverflow.com/a/77408784
            // `.first { _ in true }` is a workaround for a long-standing Swift bug with lazy + compactMap
            // See: https://github.com/swiftlang/swift/issues/48324
            let namesPair = pairs.lazy.compactMap { pair -> ((fromName: String, toName: String))? in
                guard
                    case .account(let accountName) = pair.source,
                    let toName = pair.toAccountName
                else {
                    return nil
                }

                // If fromName is nil, this means Main account has the default name
                return (accountName ?? Localization.accountMainAccountTitle, toName)
            }.first { _ in true }

            guard let namesPair else {
                return
            }

            accountsPendingAlert = AlertBuilder.makeAlert(
                title: Localization.accountsMigrationAlertTitle,
                message: Localization.accountsMigrationAlertMessage(namesPair.fromName, namesPair.toName),
                primaryButton: .default(Text(Localization.commonGotIt))
            )
        }
    }

    func showAccountsPendingAlertIfNeeded() {
        guard let pendingAlert = accountsPendingAlert else { return }

        alert = pendingAlert
        accountsPendingAlert = nil
    }

    private func loadWalletImage() {
        runTask(in: self) { viewModel in
            let imageValue = await viewModel.userWalletModel.walletImageProvider.loadSmallImage()

            await runOnMain {
                viewModel.walletImage = imageValue.image
            }
        }
    }

    func onTapNameField() {
        guard AppSettings.shared.saveUserWallets else { return }

        if let alert = AlertBuilder.makeWalletRenamingAlert(
            userWalletModel: userWalletModel,
            userWalletRepository: userWalletRepository,
            updateName: { self.name = $0 }
        ) {
            AppPresenter.shared.show(alert)
        }
    }

    func handleAccountsLimitReached() {
        alert = AlertBuilder.makeAlertWithDefaultPrimaryButton(
            title: Localization.accountAddLimitDialogTitle,
            message: Localization.accountAddLimitDialogDescription(AccountModelUtils.maxNumberOfAccounts),
            buttonText: Localization.commonGotIt
        )
    }

    func mobileUpgradeTap() {
        runTask(in: self) { viewModel in
            await viewModel.openMobileUpgrade()
        }
    }
}

// MARK: - Private

private extension UserWalletSettingsViewModel {
    func bind() {
        userWalletModel.updatePublisher
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, event in
                if case .configurationChanged = event {
                    viewModel.setupView()
                }
            }
            .store(in: &bag)

        // We should not display manageTokens row if we have visible accounts
        // because if they are visible, token management is performed from
        // their respective details screens
        accountsViewModel?
            .$accountRows
            .withWeakCaptureOf(self)
            .map { viewModel, accountRows in
                viewModel.shouldShowManageTokens(accountRows: accountRows)
                    ? viewModel.makeManageTokensRowViewModel()
                    : nil
            }
            .receiveOnMain()
            .assign(to: \.manageTokensViewModel, on: self, ownership: .weak)
            .store(in: &bag)
    }

    private func shouldShowManageTokens(accountRows: [UserSettingsAccountsViewModel.AccountRow]?) -> Bool {
        guard userWalletModel.config.hasFeature(.multiCurrency) else {
            return false
        }

        // If accounts are enabled (i.e. `accountRows` is not nil),
        // then manage tokens row should be shown only if there are no visible accounts
        // If accounts are not enabled, then manage tokens row should be always shown
        return accountRows?.isEmpty ?? true
    }

    func setupView() {
        resetViewModels()
        setupViewModels()
        setupMobileViewModels()
    }

    func resetViewModels() {
        backupViewModel = nil
        manageTokensViewModel = nil
        cardSettingsViewModel = nil
        referralViewModel = nil
        nftViewModel = nil
        pushNotificationsViewModel = nil
        mobileAccessCodeViewModel = nil
        mobileBackupViewModel = nil
        mobileUpgradeNotificationInput = nil
    }

    func setupViewModels() {
        if !userWalletModel.config.getFeatureAvailability(.backup).isHidden {
            backupViewModel = DefaultRowViewModel(
                title: Localization.detailsRowTitleCreateBackup,
                action: weakify(self, forFunction: UserWalletSettingsViewModel.prepareBackup)
            )
        }

        if shouldShowManageTokens(accountRows: accountsViewModel?.accountRows) {
            manageTokensViewModel = makeManageTokensRowViewModel()
        }

        if userWalletModel.config.hasFeature(.cardSettings) {
            cardSettingsViewModel = DefaultRowViewModel(
                title: Localization.cardSettingsTitle,
                accessibilityIdentifier: CardSettingsAccessibilityIdentifiers.deviceSettingsButton,
                action: weakify(self, forFunction: UserWalletSettingsViewModel.openCardSettings)
            )
        }

        if !userWalletModel.config.getFeatureAvailability(.referralProgram).isHidden {
            referralViewModel =
                DefaultRowViewModel(
                    title: Localization.detailsReferralTitle,
                    accessibilityIdentifier: CardSettingsAccessibilityIdentifiers.referralProgramButton,
                    action: weakify(self, forFunction: UserWalletSettingsViewModel.openReferral)
                )
        }

        if nftAvailabilityProvider.isNFTAvailable(for: userWalletModel) {
            nftViewModel = DefaultToggleRowViewModel(
                title: Localization.detailsNftTitle,
                isOn: .init(
                    root: self,
                    default: false,
                    get: { $0.isNFTEnabled },
                    set: { $0.isNFTEnabled = $1 }
                )
            )
        }

        if userTokensPushNotificationsService.entries.contains(where: { $0.id == userWalletModel.userWalletId.stringValue }) {
            pushNotificationsViewModel = TransactionNotificationsRowToggleViewModel(
                userTokensPushNotificationsManager: userWalletModel.userTokensPushNotificationsManager,
                coordinator: coordinator,
                showPushSettingsAlert: weakify(self, forFunction: UserWalletSettingsViewModel.displayEnablePushSettingsAlert)
            )
        }

        if userWalletModel.config.hasFeature(.userWalletBackup) {
            forgetViewModel = DefaultRowViewModel(
                title: Localization.settingsForgetWallet,
                action: weakify(self, forFunction: UserWalletSettingsViewModel.didTapRemoveMobileWallet)
            )
        } else {
            forgetViewModel = DefaultRowViewModel(
                title: Localization.settingsForgetWallet,
                action: weakify(self, forFunction: UserWalletSettingsViewModel.didTapForgetWallet)
            )
        }
    }

    func setupAccountsViewModel() {
        let accountModelsManager = userWalletModel.accountModelsManager

        guard FeatureProvider.isAvailable(.accounts), accountModelsManager.canAddCryptoAccounts else {
            return
        }

        accountsViewModel = UserSettingsAccountsViewModel(
            accountModelsManager: accountModelsManager,
            userWalletConfig: userWalletModel.config,
            coordinator: coordinator
        )
    }

    func setupMobileViewModels() {
        mobileSettingsUtil.walletSettings.forEach { setting in
            switch setting {
            case .setAccessCode:
                mobileAccessCodeViewModel = DefaultRowViewModel(
                    title: Localization.walletSettingsSetAccessCodeTitle,
                    action: weakify(self, forFunction: UserWalletSettingsViewModel.mobileAccessCodeTap)
                )

            case .changeAccessCode:
                mobileAccessCodeViewModel = DefaultRowViewModel(
                    title: Localization.walletSettingsChangeAccessCodeTitle,
                    action: weakify(self, forFunction: UserWalletSettingsViewModel.mobileAccessCodeTap)
                )

            case .backup(let needsBackup):
                let detailsType: DefaultRowViewModel.DetailsType?
                if needsBackup {
                    let badgeItem = BadgeView.Item(title: Localization.hwBackupNoBackup, style: .warning)
                    detailsType = .badge(badgeItem)
                } else {
                    detailsType = nil
                }

                mobileBackupViewModel = DefaultRowViewModel(
                    title: Localization.commonBackup,
                    detailsType: detailsType,
                    action: weakify(self, forFunction: UserWalletSettingsViewModel.openMobileBackupTypes)
                )

            case .upgrade:
                mobileUpgradeNotificationInput = mobileSettingsUtil.makeUpgradeNotificationInput(
                    onUpgrade: weakify(self, forFunction: UserWalletSettingsViewModel.onMobileUpgradeNotificationUpgrade),
                    onDismiss: weakify(self, forFunction: UserWalletSettingsViewModel.onMobileUpgradeNotificationDismiss)
                )
            }
        }
    }

    func onMobileUpgradeNotificationUpgrade() {
        let isBackupNeeded = userWalletModel.config.hasFeature(.mnemonicBackup) && userWalletModel.config.hasFeature(.iCloudBackup)

        runTask(in: self) { viewModel in
            if isBackupNeeded {
                viewModel.logMobileBackupNeededAnalytics(action: .upgrade)
                await viewModel.openMobileBackupToUpgradeNeeded()
            } else {
                await viewModel.upgradeMobileWallet()
            }
        }
    }

    func upgradeMobileWallet() async {
        let unlockResult = await mobileUnlock()

        switch unlockResult {
        case .successful(let context):
            await openMobileUpgradeToHardwareWallet(context: context)
        case .canceled:
            break
        case .failed(let error):
            alert = error.alertBinder
        }
    }

    func onMobileBackupToUpgradeComplete() {
        runTask(in: self) { viewModel in
            await viewModel.closeOnboarding()
            await viewModel.upgradeMobileWallet()
        }
    }

    func onMobileUpgradeNotificationDismiss() {
        setupView()
    }

    func mobileAccessCodeTap() {
        logMobileAccessCodeTapAnalytics()
        mobileAccessCodeAction()
    }

    func mobileAccessCodeAction() {
        runTask(in: self) { viewModel in
            let state = await viewModel.mobileSettingsUtil.calculateAccessCodeState()

            await runOnMain {
                switch state {
                case .needsBackup:
                    viewModel.logMobileBackupNeededAnalytics(action: .accessCode)
                    viewModel.openMobileBackupNeeded()
                case .onboarding(let context):
                    viewModel.openMobileAccessCodeOnboarding(context: context)
                case .none:
                    break
                }
            }
        }
    }

    func prepareBackup() {
        logBackupTapAnalytics()
        if let backupInput = userWalletModel.backupInput {
            openOnboarding(with: .input(backupInput))
        }
    }

    func didTapForgetWallet() {
        Analytics.log(.buttonDeleteWalletTapped, contextParams: analyticsContextParams)

        let deleteButton = ConfirmationDialogViewModel.Button(
            title: Localization.commonForget,
            role: .destructive,
            action: { [weak self] in
                self?.didConfirmWalletDeletion()
            }
        )

        forgetWalletConfirmationDialog = ConfirmationDialogViewModel(
            title: Localization.userWalletListDeletePrompt,
            buttons: [
                deleteButton,
                ConfirmationDialogViewModel.Button.cancel,
            ]
        )
    }

    func didTapRemoveMobileWallet() {
        coordinator?.openMobileRemoveWalletNotification(userWalletModel: userWalletModel)
    }

    func didConfirmWalletDeletion() {
        userWalletRepository.delete(userWalletId: userWalletModel.userWalletId)
        coordinator?.dismiss()
    }

    func showErrorAlert(error: Error) {
        alert = AlertBuilder.makeOkErrorAlert(message: error.localizedDescription)
    }

    func makeManageTokensRowViewModel() -> DefaultRowViewModel {
        DefaultRowViewModel(
            title: Localization.mainManageTokens,
            accessibilityIdentifier: CardSettingsAccessibilityIdentifiers.manageTokensButton,
            action: weakify(self, forFunction: UserWalletSettingsViewModel.openManageTokens)
        )
    }

    func displayEnablePushSettingsAlert() {
        let buttons: AlertBuilder.Buttons = .init(
            primaryButton: .default(
                Text(Localization.pushNotificationsPermissionAlertNegativeButton),
                action: { [weak self] in
                    self?.pushNotificationsViewModel?.isPushNotifyEnabled = false
                }
            ),
            secondaryButton: .default(
                Text(Localization.pushNotificationsPermissionAlertPositiveButton),
                action: { [weak self] in
                    self?.pushNotificationsViewModel?.isPushNotifyEnabled = false
                    self?.coordinator?.openAppSettings()
                }
            )
        )

        alert = AlertBuilder.makeAlert(
            title: Localization.pushNotificationsPermissionAlertTitle,
            message: Localization.pushNotificationsPermissionAlertDescription,
            with: buttons
        )
    }
}

// MARK: - Navigation

private extension UserWalletSettingsViewModel {
    func openOnboarding(with options: OnboardingCoordinator.Options) {
        coordinator?.openOnboardingModal(with: options)
    }

    func openManageTokens() {
        Analytics.log(.settingsButtonManageTokens, contextParams: analyticsContextParams)

        guard
            let currentWalletModelsManager,
            let currentUserTokensManager
        else {
            return
        }

        coordinator?.openManageTokens(
            walletModelsManager: currentWalletModelsManager,
            userTokensManager: currentUserTokensManager,
            userWalletConfig: userWalletModel.config
        )
    }

    func openCardSettings() {
        Analytics.log(.buttonCardSettings, contextParams: analyticsContextParams)

        let scanParameters = CardScannerParameters(
            shouldAskForAccessCodes: true,
            performDerivations: false,
            sessionFilter: userWalletModel.config.cardSessionFilter
        )

        let scanner = CardScannerFactory().makeScanner(
            with: userWalletModel.config.makeTangemSdk(),
            parameters: scanParameters
        )

        coordinator?.openScanCardSettings(
            with: .init(
                cardImageProvider: userWalletModel.walletImageProvider,
                cardScanner: scanner
            )
        )
    }

    func openReferral() {
        if let disabledLocalizedReason = userWalletModel.config.getDisabledLocalizedReason(for: .referralProgram) {
            alert = AlertBuilder.makeDemoAlert(disabledLocalizedReason)
            return
        }

        // accounts_fixes_needed_none
        let workMode: ReferralViewModel.WorkMode = FeatureProvider.isAvailable(.accounts)
            ? .accounts(userWalletModel.accountModelsManager)
            : .plainUserTokensManager(userWalletModel.userTokensManager)

        let input = ReferralInputModel(
            userWalletId: userWalletModel.userWalletId.value,
            supportedBlockchains: userWalletModel.config.supportedBlockchains,
            workMode: workMode,
            tokenIconInfoBuilder: TokenIconInfoBuilder(),
            userWalletModel: userWalletModel
        )

        coordinator?.openReferral(input: input)
    }

    func openMobileBackupNeeded() {
        coordinator?.openMobileBackupNeeded(
            userWalletModel: userWalletModel,
            source: .walletSettings(action: .accessCode),
            onBackupFinished: weakify(self, forFunction: UserWalletSettingsViewModel.mobileAccessCodeAction)
        )
    }

    func openMobileAccessCodeOnboarding(context: MobileWalletContext) {
        let flow = MobileOnboardingFlow.accessCode(
            userWalletModel: userWalletModel,
            source: .walletSettings(action: .none),
            context: context
        )
        let input = MobileOnboardingInput(flow: flow)
        openOnboarding(with: .mobileInput(input))
    }

    func openMobileBackupTypes() {
        logMobileBackupTapAnalytics()
        coordinator?.openMobileBackupTypes(userWalletModel: userWalletModel)
    }

    @MainActor
    func openMobileUpgradeToHardwareWallet(context: MobileWalletContext) {
        coordinator?.openMobileUpgradeToHardwareWallet(userWalletModel: userWalletModel, context: context)
    }

    @MainActor
    func openMobileBackupToUpgradeNeeded() {
        coordinator?.openMobileBackupToUpgradeNeeded(
            onBackupRequested: weakify(self, forFunction: UserWalletSettingsViewModel.openBackupMobileWallet)
        )
    }

    @MainActor
    func openBackupMobileWallet() {
        let input = MobileOnboardingInput(flow: .seedPhraseBackupToUpgrade(
            userWalletModel: userWalletModel,
            source: .walletSettings(action: .upgrade),
            onContinue: weakify(self, forFunction: UserWalletSettingsViewModel.onMobileBackupToUpgradeComplete)
        ))
        coordinator?.openOnboardingModal(with: .mobileInput(input))
    }

    @MainActor
    func openMobileUpgrade() {
        coordinator?.openHardwareBackupTypes(userWalletModel: userWalletModel)
    }

    @MainActor
    func closeOnboarding() {
        coordinator?.closeOnboarding()
    }
}

// MARK: - Mobile wallet unlocking

private extension UserWalletSettingsViewModel {
    func mobileUnlock() async -> MobileUnlockResult {
        do {
            let authUtil = MobileAuthUtil(
                userWalletId: userWalletModel.userWalletId,
                config: userWalletModel.config,
                biometricsProvider: CommonUserWalletBiometricsProvider()
            )
            let result = try await authUtil.unlock()

            switch result {
            case .successful(let context):
                return .successful(context: context)

            case .canceled:
                return .canceled

            case .userWalletNeedsToDelete:
                assertionFailure("Unexpected state: .userWalletNeedsToDelete should never happen.")
                return .canceled
            }

        } catch {
            return .failed(error: error)
        }
    }

    enum MobileUnlockResult {
        case successful(context: MobileWalletContext)
        case canceled
        case failed(error: Error)
    }
}

// MARK: - DependencyUpdater

private extension UserWalletSettingsViewModel {
    /// Encapsulates logic for updating wallet and tokens managers based on account mode
    final class DependencyUpdater {
        private let userWalletModel: UserWalletModel
        private weak var owner: UserWalletSettingsViewModel?
        private var bag = Set<AnyCancellable>()

        init(userWalletModel: UserWalletModel) {
            self.userWalletModel = userWalletModel
        }

        func setup(owner: UserWalletSettingsViewModel) {
            self.owner = owner
            setupDependencies()
        }

        private func setupDependencies() {
            if FeatureProvider.isAvailable(.accounts) {
                userWalletModel
                    .accountModelsManager
                    .accountModelsPublisher
                    .receiveOnMain()
                    .withWeakCaptureOf(self)
                    .sink { viewModel, accountModels in
                        viewModel.updateManagersForAccountMode(accountModels: accountModels)
                    }
                    .store(in: &bag)
            } else {
                // accounts_fixes_needed_none
                updateManagers(
                    walletModelsManager: userWalletModel.walletModelsManager,
                    userTokensManager: userWalletModel.userTokensManager
                )
            }
        }

        private func updateManagersForAccountMode(accountModels: [AccountModel]) {
            let canAddCryptoAccounts = userWalletModel.accountModelsManager.canAddCryptoAccounts

            switch accountModels.firstStandard() {
            case .standard(.single(let cryptoAccountModel)):
                // In single account mode we support managing tokens from this screen, so we inject required dependencies
                updateManagers(
                    walletModelsManager: cryptoAccountModel.walletModelsManager,
                    userTokensManager: cryptoAccountModel.userTokensManager
                )
            case .standard(.multiple(let cryptoAccountModels)) where !canAddCryptoAccounts && cryptoAccountModels.count == 1:
                // In multiple accounts mode but on wallets w/o derivation support we support managing tokens from this screen,
                // so we inject required dependencies from the first account model (main account)
                updateManagers(
                    walletModelsManager: cryptoAccountModels.first?.walletModelsManager,
                    userTokensManager: cryptoAccountModels.first?.userTokensManager
                )
            case .standard(.multiple):
                // In multiple accounts case we don't support managing tokens from this screen,
                // instead users should manage tokens from respective account details screens
                updateManagers(walletModelsManager: nil, userTokensManager: nil)
            case .none:
                updateManagers(walletModelsManager: nil, userTokensManager: nil)
            }
        }

        private func updateManagers(
            walletModelsManager: WalletModelsManager?,
            userTokensManager: UserTokensManager?
        ) {
            owner?.currentWalletModelsManager = walletModelsManager
            owner?.currentUserTokensManager = userTokensManager
        }
    }
}

// MARK: - Analytics

private extension UserWalletSettingsViewModel {
    func logScreenOpenedAnalytics() {
        var params: [Analytics.ParameterKey: String] = [:]

        if FeatureProvider.isAvailable(.accounts) {
            params[.accountsCount] = String(userWalletModel.accountModelsManager.accountModels.cryptoAccountsCount)
        }

        Analytics.log(
            event: .walletSettingsScreenOpened,
            params: params,
            contextParams: analyticsContextParams
        )
    }

    func logMobileBackupNeededAnalytics(action: Analytics.ParameterValue) {
        Analytics.log(
            .walletSettingsNoticeBackupFirst,
            params: [
                .source: .walletSettings,
                .action: action,
            ],
            contextParams: analyticsContextParams
        )
    }

    func logMobileAccessCodeTapAnalytics() {
        let hasAccessCode = userWalletModel.config.userWalletAccessCodeStatus.hasAccessCode
        Analytics.log(
            .walletSettingsButtonAccessCode,
            params: [.action: hasAccessCode ? .changing : .set],
            contextParams: analyticsContextParams
        )
    }

    func logMobileBackupTapAnalytics() {
        Analytics.log(.walletSettingsButtonBackup, contextParams: analyticsContextParams)
    }

    func logBackupTapAnalytics() {
        Analytics.log(.buttonCreateBackup, contextParams: analyticsContextParams)
    }
}
