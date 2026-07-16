//
//  UserWalletSettingsViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import CombineExt
import TangemLocalization
import TangemFoundation
import TangemAccessibilityIdentifiers
import TangemMobileWalletSdk
import TangemAssets
import struct SwiftUI.Image
import struct SwiftUI.Text
import struct TangemUIUtils.AlertBinder
import struct TangemUIUtils.ConfirmationDialogViewModel

final class UserWalletSettingsViewModel: ObservableObject {
    // MARK: - Injected

    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.nftAvailabilityProvider) private var nftAvailabilityProvider: NFTAvailabilityProvider

    // MARK: - ViewState

    @Published private(set) var name: String
    @Published private(set) var walletImage: Image?

    @Published var accountsViewModel: UserSettingsAccountsViewModel?
    @Published var mobileAccessCodeViewModel: DefaultRowViewModel?
    @Published var backupViewModel: DefaultRowViewModel?

    var commonSectionModels: [DefaultRowViewModel] {
        [mobileBackupViewModel, manageTokensViewModel, cardSettingsViewModel, referralViewModel, notificationSettingsViewModel].compactMap { $0 }
    }

    var isMobileUpgradeAvailable: Bool {
        userWalletModel.config.hasFeature(.userWalletUpgrade)
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
    @Published private var notificationSettingsViewModel: DefaultRowViewModel?

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

    func onFirstAppear() {
        logScreenOpenedAnalytics()
    }

    func onAppear() {
        setupView()
        loadWalletImage()
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

        // No weak self capture in closures here because shared presenter is used
        if let alert = AlertBuilder.makeWalletRenamingAlert(
            userWalletModel: userWalletModel,
            userWalletRepository: userWalletRepository,
            updateName: { newName in
                self.name = newName
                self.coordinator?.onAlertDismiss()
            },
            onCancel: {
                self.coordinator?.onAlertDismiss()
            }
        ) {
            AppPresenter.shared.show(alert)
        }
    }

    func handleAccountsLimitReached() {
        alert = AlertBuilder.makeAlertWithDefaultPrimaryButton(
            title: Localization.accountAddLimitDialogTitle,
            message: Localization.accountAddLimitDialogDescription(AccountModelUtils.maxNumberOfAccounts),
            buttonText: Localization.commonGotIt
        ) { [weak self] in
            self?.coordinator?.onAlertDismiss()
        }
    }

    func handleAccountsRedistribution(sourceAccountName: String, targetAccountName: String) {
        alert = AlertBuilder.makeAlertWithDefaultPrimaryButton(
            title: Localization.accountsMigrationAlertTitle,
            message: Localization.accountsMigrationAlertMessage(sourceAccountName, targetAccountName),
            buttonText: Localization.commonGotIt
        ) { [weak self] in
            self?.coordinator?.onAlertDismiss()
        }
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
        notificationSettingsViewModel = nil
        mobileAccessCodeViewModel = nil
        mobileBackupViewModel = nil
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

        if FeatureProvider.isAvailable(.pushNotificationsSettings) {
            notificationSettingsViewModel = DefaultRowViewModel(
                title: Localization.pushNotificationSettingsTitle,
                action: weakify(self, forFunction: UserWalletSettingsViewModel.openNotificationSettings)
            )
        } else {
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

        guard accountModelsManager.canAddCryptoAccounts else {
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
            }
        }
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
        alert = AlertBuilder.makeOkErrorAlert(message: error.localizedDescription) { [weak self] in
            self?.coordinator?.onAlertDismiss()
        }
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
                    guard let self else { return }

                    pushNotificationsViewModel?.isPushNotifyEnabled = false
                    coordinator?.onAlertDismiss()
                }
            ),
            secondaryButton: .default(
                Text(Localization.pushNotificationsPermissionAlertPositiveButton),
                action: { [weak self] in
                    guard let self else { return }

                    pushNotificationsViewModel?.isPushNotifyEnabled = false
                    coordinator?.openAppSettings()
                    coordinator?.onAlertDismiss()
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
            shouldCheckAccessCode: false,
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

    func openNotificationSettings() {
        coordinator?.openNotificationSettings(userWalletModel: userWalletModel)
    }

    func openReferral() {
        if let disabledLocalizedReason = userWalletModel.config.getDisabledLocalizedReason(for: .referralProgram) {
            alert = AlertBuilder.makeDemoAlert(disabledLocalizedReason) { [weak self] in
                self?.coordinator?.onAlertDismiss()
            }
            return
        }

        let input = ReferralInputModel(
            userWalletId: userWalletModel.userWalletId.value,
            supportedBlockchains: userWalletModel.config.supportedBlockchains,
            accountModelsManager: userWalletModel.accountModelsManager,
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
    func openMobileUpgrade() {
        coordinator?.openHardwareBackupTypes(userWalletModel: userWalletModel)
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
            userWalletModel
                .accountModelsManager
                .accountModelsPublisher
                .receiveOnMain()
                .withWeakCaptureOf(self)
                .sink { viewModel, accountModels in
                    viewModel.updateManagersForAccountMode(accountModels: accountModels)
                }
                .store(in: &bag)
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
            case .standard(.multiple), .tangemPay:
                // In multiple accounts case we don't support managing tokens from this screen,
                // instead users should manage tokens from respective account details screens.
                // TangemPay currently doesn't support managing tokens at all
                updateManagers(walletModelsManager: nil, userTokensManager: nil)
            case .none:
                // Reachable case - the saved wallet has been deleted from the app
                // Erasing all dependencies since they aren't needed anymore
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

        params[.accountsCount] = String(userWalletModel.accountModelsManager.accountModels.cryptoAccountsCount)

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
