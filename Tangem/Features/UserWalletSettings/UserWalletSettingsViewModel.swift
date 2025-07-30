//
//  UserWalletSettingsViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import TangemLocalization
import TangemFoundation
import TangemAccessibilityIdentifiers
import struct TangemUIUtils.ActionSheetBinder
import struct TangemUIUtils.AlertBinder

final class UserWalletSettingsViewModel: ObservableObject {
    // MARK: - Injected

    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.nftAvailabilityProvider) private var nftAvailabilityProvider: NFTAvailabilityProvider

    // MARK: - ViewState

    @Published private(set) var name: String
    @Published var accountsSection: [AccountsSectionType] = []
    @Published var hotAccessCodeViewModel: DefaultRowViewModel?
    @Published var backupViewModel: DefaultRowViewModel?

    var commonSectionModels: [DefaultRowViewModel] {
        [hotBackupViewModel, manageTokensViewModel, cardSettingsViewModel, referralViewModel].compactMap { $0 }
    }

    @Published var nftViewModel: DefaultToggleRowViewModel?
    @Published var pushNotificationsViewModel: TransactionNotificationsRowToggleViewModel?

    @Published var forgetViewModel: DefaultRowViewModel?

    @Published var alert: AlertBinder?
    @Published var actionSheet: ActionSheetBinder?

    // MARK: - Private

    @Published private var hotBackupViewModel: DefaultRowViewModel?
    @Published private var manageTokensViewModel: DefaultRowViewModel?
    @Published private var cardSettingsViewModel: DefaultRowViewModel?
    @Published private var referralViewModel: DefaultRowViewModel?

    private let hotSettingsUtil: HotSettingsUtil

    private var isNFTEnabled: Bool {
        get { nftAvailabilityProvider.isNFTEnabled(for: userWalletModel) }
        set { nftAvailabilityProvider.setNFTEnabled(newValue, for: userWalletModel) }
    }

    // MARK: - Dependencies

    private let userWalletModel: UserWalletModel
    private weak var coordinator: UserWalletSettingsRoutable?

    init(
        userWalletModel: UserWalletModel,
        coordinator: UserWalletSettingsRoutable
    ) {
        name = userWalletModel.name
        hotSettingsUtil = HotSettingsUtil(userWalletModel: userWalletModel)

        self.userWalletModel = userWalletModel
        self.coordinator = coordinator
    }

    func onAppear() {
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
    func setupView() {
        // setupAccountsSection()
        setupViewModels()
        setupHotViewModels()
    }

    func setupAccountsSection() {
        // [REDACTED_TODO_COMMENT]
        accountsSection = []
    }

    func setupViewModels() {
        if !userWalletModel.config.getFeatureAvailability(.backup).isHidden {
            backupViewModel = DefaultRowViewModel(
                title: Localization.detailsRowTitleCreateBackup,
                action: weakify(self, forFunction: UserWalletSettingsViewModel.prepareBackup)
            )
        } else {
            backupViewModel = nil
        }

        if userWalletModel.config.hasFeature(.multiCurrency) {
            manageTokensViewModel = .init(
                title: Localization.mainManageTokens,
                action: weakify(self, forFunction: UserWalletSettingsViewModel.openManageTokens)
            )
        }

        cardSettingsViewModel = DefaultRowViewModel(
            title: Localization.cardSettingsTitle,
            action: weakify(self, forFunction: UserWalletSettingsViewModel.openCardSettings)
        )

        if !userWalletModel.config.getFeatureAvailability(.referralProgram).isHidden {
            referralViewModel =
                DefaultRowViewModel(
                    title: Localization.detailsReferralTitle,
                    action: weakify(self, forFunction: UserWalletSettingsViewModel.openReferral),
                    accessibilityIdentifier: CardSettingsAccessibilityIdentifiers.referralProgramButton
                )
        } else {
            referralViewModel = nil
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
        } else {
            nftViewModel = nil
        }

        if FeatureProvider.isAvailable(.pushTransactionNotifications) {
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

    func setupHotViewModels() {
        hotSettingsUtil.walletSettings.forEach { setting in
            switch setting {
            case .accessCode:
                hotAccessCodeViewModel = DefaultRowViewModel(
                    title: Localization.walletSettingsAccessCodeTitle,
                    action: weakify(self, forFunction: UserWalletSettingsViewModel.hotAccessCodeAction)
                )
            case .backup(let hasBackup):
                let detailsType: DefaultRowViewModel.DetailsType?
                if hasBackup {
                    detailsType = nil
                } else {
                    let badgeItem = BadgeView.Item(title: Localization.hwBackupNoBackup, style: .warning)
                    detailsType = .badge(badgeItem)
                }

                hotBackupViewModel = DefaultRowViewModel(
                    title: Localization.commonBackup,
                    detailsType: detailsType,
                    action: weakify(self, forFunction: UserWalletSettingsViewModel.openHotBackupTypes)
                )
            }
        }
    }

    func hotAccessCodeAction() {
        runTask(in: self) { viewModel in
            let result = await viewModel.hotSettingsUtil.performAccessCodeAction()

            switch result {
            case .backupNeeded:
                viewModel.openHotBackupNeeded()
            case .onboarding(let needsValidation):
                viewModel.openHotAccessCodeOnboarding(needsValidation: needsValidation)
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

        let sheet = ActionSheet(
            title: Text(Localization.userWalletListDeletePrompt),
            buttons: [
                .destructive(
                    Text(Localization.commonDelete),
                    action: weakify(self, forFunction: UserWalletSettingsViewModel.didConfirmWalletDeletion)
                ),
                .cancel(Text(Localization.commonCancel)),
            ]
        )
        actionSheet = ActionSheetBinder(sheet: sheet)
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

        coordinator?.openManageTokens(userWalletModel: userWalletModel)
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

    func openHotBackupNeeded() {
        coordinator?.openHotBackupNeeded()
    }

    func openHotAccessCodeOnboarding(needsValidation: Bool) {
        let input = HotOnboardingInput(flow: .accessCodeChange(needAccessCodeValidation: needsValidation))
        openOnboarding(with: .hotInput(input))
    }

    func openHotBackupTypes() {
        coordinator?.openHotBackupTypes()
    }
}

// MARK: - Data

extension UserWalletSettingsViewModel {
    enum AccountsSectionType: Identifiable {
        case header
        case account(DefaultRowViewModel) // [REDACTED_TODO_COMMENT]
        case addNewAccountButton(DefaultRowViewModel)

        var id: Int {
            switch self {
            case .header:
                return "header".hashValue
            case .account(let viewModel):
                return viewModel.id.hashValue
            case .addNewAccountButton(let viewModel):
                return viewModel.id.hashValue
            }
        }
    }
}
