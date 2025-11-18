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

final class UserWalletSettingsViewModel: ObservableObject {
    // MARK: - Injected

    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.nftAvailabilityProvider) private var nftAvailabilityProvider: NFTAvailabilityProvider
    @Injected(\.userTokensPushNotificationsService) private var userTokensPushNotificationsService: UserTokensPushNotificationsService

    // MARK: - ViewState

    @Published private(set) var name: String
    @Published var accountsViewModel: UserSettingsAccountsViewModel?
    @Published var mobileUpgradeNotificationInput: NotificationViewInput?
    @Published var mobileAccessCodeViewModel: DefaultRowViewModel?
    @Published var backupViewModel: DefaultRowViewModel?

    var commonSectionModels: [DefaultRowViewModel] {
        [mobileBackupViewModel, manageTokensViewModel, cardSettingsViewModel, referralViewModel].compactMap { $0 }
    }

    @Published var nftViewModel: DefaultToggleRowViewModel?
    @Published var pushNotificationsViewModel: TransactionNotificationsRowToggleViewModel?

    @Published var forgetViewModel: DefaultRowViewModel?

    @Published var alert: AlertBinder?
    @Published var confirmationDialog: ConfirmationDialogViewModel?

    // MARK: - Private

    @Published private var mobileBackupViewModel: DefaultRowViewModel?
    @Published private var manageTokensViewModel: DefaultRowViewModel?
    @Published private var cardSettingsViewModel: DefaultRowViewModel?
    @Published private var referralViewModel: DefaultRowViewModel?

    private let mobileSettingsUtil: MobileSettingsUtil

    private var isNFTEnabled: Bool {
        get { nftAvailabilityProvider.isNFTEnabled(for: userWalletModel) }
        set { nftAvailabilityProvider.setNFTEnabled(newValue, for: userWalletModel) }
    }

    // MARK: - Dependencies

    private let userWalletModel: UserWalletModel
    private weak var coordinator: UserWalletSettingsRoutable?

    private var bag = Set<AnyCancellable>()

    init(
        userWalletModel: UserWalletModel,
        coordinator: UserWalletSettingsRoutable
    ) {
        name = userWalletModel.name
        mobileSettingsUtil = MobileSettingsUtil(userWalletModel: userWalletModel)

        self.userWalletModel = userWalletModel
        self.coordinator = coordinator

        bind()
    }

    func onAppear() {
        Analytics.log(.walletSettingsScreenOpened)

        setupView()
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
}

// MARK: - Private

private extension UserWalletSettingsViewModel {
    func bind() {
        userWalletModel.updatePublisher
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { viewModel, event in
                if case .configurationChanged = event {
                    viewModel.setupView()
                }
            }
            .store(in: &bag)

        if FeatureProvider.isAvailable(.accounts) {
            userWalletModel.accountModelsManager
                .accountModelsPublisher
                .withWeakCaptureOf(self)
                .map { viewModel, accounts in
                    UserSettingsAccountsViewModel(
                        accountModels: accounts,
                        accountModelsManager: viewModel.userWalletModel.accountModelsManager,
                        userWalletConfig: viewModel.userWalletModel.config,
                        coordinator: viewModel.coordinator
                    )
                }
                .assign(to: \.accountsViewModel, on: self, ownership: .weak)
                .store(in: &bag)
        }
    }

    func setupView() {
        resetViewModels()
        // setupAccountsSection()
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

        if userWalletModel.config.hasFeature(.multiCurrency) {
            manageTokensViewModel = .init(
                title: Localization.mainManageTokens,
                action: weakify(self, forFunction: UserWalletSettingsViewModel.openManageTokens)
            )
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

        forgetViewModel = DefaultRowViewModel(
            title: Localization.settingsForgetWallet,
            action: weakify(self, forFunction: UserWalletSettingsViewModel.didTapDeleteWallet)
        )
    }

    func setupMobileViewModels() {
        mobileSettingsUtil.walletSettings.forEach { setting in
            switch setting {
            case .setAccessCode:
                mobileAccessCodeViewModel = DefaultRowViewModel(
                    title: Localization.walletSettingsSetAccessCodeTitle,
                    action: weakify(self, forFunction: UserWalletSettingsViewModel.mobileAccessCodeAction)
                )

            case .changeAccessCode:
                mobileAccessCodeViewModel = DefaultRowViewModel(
                    title: Localization.walletSettingsChangeAccessCodeTitle,
                    action: weakify(self, forFunction: UserWalletSettingsViewModel.mobileAccessCodeAction)
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
                    onContext: weakify(self, forFunction: UserWalletSettingsViewModel.onMobileUpgradeNotificationContext),
                    onDismiss: weakify(self, forFunction: UserWalletSettingsViewModel.onMobileUpgradeNotificationDismiss)
                )
            }
        }
    }

    func onMobileUpgradeNotificationContext(context: MobileWalletContext) {
        coordinator?.openMobileUpgrade(userWalletModel: userWalletModel, context: context)
    }

    func onMobileUpgradeNotificationDismiss() {
        setupView()
    }

    func mobileAccessCodeAction() {
        let hasAccessCode = userWalletModel.config.hasFeature(.userWalletAccessCode)
        Analytics.log(.walletSettingsButtonAccessCode, params: [.action: hasAccessCode ? .changing : .set])

        runTask(in: self) { viewModel in
            let state = await viewModel.mobileSettingsUtil.calculateAccessCodeState()

            await runOnMain {
                switch state {
                case .needsBackup:
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
        Analytics.log(.buttonCreateBackup)
        if let backupInput = userWalletModel.backupInput {
            openOnboarding(with: .input(backupInput))
        }
    }

    func didTapDeleteWallet() {
        Analytics.log(.buttonDeleteWalletTapped)

        let deleteButton = ConfirmationDialogViewModel.Button(
            title: Localization.commonDelete,
            role: .destructive,
            action: { [weak self] in
                self?.didConfirmWalletDeletion()
            }
        )

        confirmationDialog = ConfirmationDialogViewModel(
            title: Localization.userWalletListDeletePrompt,
            buttons: [
                deleteButton,
                ConfirmationDialogViewModel.Button.cancel,
            ]
        )
    }

    func didConfirmWalletDeletion() {
        userWalletRepository.delete(userWalletId: userWalletModel.userWalletId)
        coordinator?.dismiss()
    }

    func showErrorAlert(error: Error) {
        alert = AlertBuilder.makeOkErrorAlert(message: error.localizedDescription)
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
        Analytics.log(.settingsButtonManageTokens)

        coordinator?.openManageTokens(
            walletModelsManager: userWalletModel.walletModelsManager,
            userTokensManager: userWalletModel.userTokensManager,
            userWalletConfig: userWalletModel.config
        )
    }

    func openCardSettings() {
        Analytics.log(.buttonCardSettings)

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

        let input = ReferralInputModel(
            userWalletId: userWalletModel.userWalletId.value,
            supportedBlockchains: userWalletModel.config.supportedBlockchains,
            userTokensManager: userWalletModel.userTokensManager
        )

        coordinator?.openReferral(input: input)
    }

    func openMobileBackupNeeded() {
        coordinator?.openMobileBackupNeeded(userWalletModel: userWalletModel)
    }

    func openMobileAccessCodeOnboarding(context: MobileWalletContext) {
        let flow = MobileOnboardingFlow.accessCode(userWalletModel: userWalletModel, context: context)
        let input = MobileOnboardingInput(flow: flow)
        openOnboarding(with: .mobileInput(input))
    }

    func openMobileBackupTypes() {
        Analytics.log(.walletSettingsButtonBackup)

        coordinator?.openMobileBackupTypes(userWalletModel: userWalletModel)
    }
}
