//
//  DetailsCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import class UIKit.UIApplication
import struct TangemMobileWalletSdk.MobileWalletContext

final class DetailsCoordinator: CoordinatorObject {
    // MARK: - Dependencies

    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    @Injected(\.mailComposePresenter) private var mailPresenter: MailComposePresenter
    @Injected(\.safariManager) private var safariManager: SafariManager
    @Injected(\.connectedDAppRepository) private var connectedDAppRepository: any WalletConnectConnectedDAppRepository
    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: FloatingSheetPresenter

    // MARK: - Main view model

    @Published private(set) var detailsViewModel: DetailsViewModel?

    // MARK: - Child coordinators

    @Published var walletConnectCoordinator: WalletConnectCoordinator?
    @Published var userWalletSettingsCoordinator: UserWalletSettingsCoordinator?
    @Published var modalOnboardingCoordinator: OnboardingCoordinator?
    @Published var appSettingsCoordinator: AppSettingsCoordinator?
    @Published var addWalletSelectorCoordinator: AddWalletSelectorCoordinator?
    @Published var tangemPayOnboardingCoordinator: TangemPayOnboardingCoordinator?
    @Published var mobileUpgradeCoordinator: MobileUpgradeCoordinator?

    // MARK: - Child view models

    @Published var tangemPayWalletSelectorViewModel: TangemPayWalletSelectorViewModel?
    @Published var supportChatViewModel: SupportChatViewModel?
    @Published var tosViewModel: DetailsTOSViewModel?
    @Published var environmentSetupCoordinator: EnvironmentSetupCoordinator?
    @Published var logsViewModel: LogsViewModel?

    // MARK: - Helpers

    @Published var modalOnboardingCoordinatorKeeper: Bool = false

    required init(dismissAction: @escaping Action<Void>, popToRootAction: @escaping Action<PopToRootOptions>) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: DetailsCoordinator.Options) {
        Task { @MainActor in
            detailsViewModel = DetailsViewModel(coordinator: self)
        }
    }
}

// MARK: - Options

extension DetailsCoordinator {
    enum Options {
        case `default`
    }
}

// MARK: - DetailsRoutable

extension DetailsCoordinator: DetailsRoutable {
    func openWalletConnect(with disabledLocalizedReason: String?) {
        Task { @MainActor in
            let coordinator = WalletConnectCoordinator()

            let options = WalletConnectCoordinator.Options(
                disabledLocalizedReason: disabledLocalizedReason,
                prefetchedConnectedDApps: await connectedDAppRepository.prefetchedDApps
            )
            coordinator.start(with: options)
            walletConnectCoordinator = coordinator
        }
    }

    func openWalletSettings(options: UserWalletSettingsCoordinator.InputOptions) {
        let dismissAction: Action<UserWalletSettingsCoordinator.OutputOptions> = { [weak self] options in
            switch options {
            case .main:
                self?.dismiss()
            case .dismiss:
                self?.userWalletSettingsCoordinator = nil
            }
        }

        let coordinator = UserWalletSettingsCoordinator(dismissAction: dismissAction, popToRootAction: popToRootAction)
        coordinator.start(with: options)
        userWalletSettingsCoordinator = coordinator
    }

    func openOnboardingModal(options: OnboardingCoordinator.Options) {
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

    // [REDACTED_TODO_COMMENT]
    func openAddWallet() {
        let dismissAction: Action<AddWalletSelectorCoordinator.OutputOptions> = { [weak self] options in
            switch options {
            case .main:
                self?.dismiss()
            }
        }

        let coordinator = AddWalletSelectorCoordinator(dismissAction: dismissAction)
        let inputOptions = AddWalletSelectorCoordinator.InputOptions(source: .settings)
        coordinator.start(with: inputOptions)
        addWalletSelectorCoordinator = coordinator
    }

    func openMobileBackupToUpgradeNeeded(onBackupRequested: @escaping () -> Void) {
        let sheet = MobileBackupToUpgradeNeededViewModel(coordinator: self, onBackup: onBackupRequested)
        floatingSheetPresenter.enqueue(sheet: sheet)
    }

    func openMobileUpgradeToHardwareWallet(userWalletModel: UserWalletModel, context: MobileWalletContext) {
        let dismissAction: Action<MobileUpgradeCoordinator.OutputOptions> = { [weak self] options in
            switch options {
            case .dismiss:
                self?.mobileUpgradeCoordinator = nil
            case .main:
                self?.dismiss()
            }
        }

        let coordinator = MobileUpgradeCoordinator(dismissAction: dismissAction)
        let inputOptions = MobileUpgradeCoordinator.InputOptions(userWalletModel: userWalletModel, context: context)
        coordinator.start(with: inputOptions)
        mobileUpgradeCoordinator = coordinator
    }

    func openAppSettings() {
        let coordinator = AppSettingsCoordinator(popToRootAction: popToRootAction)
        coordinator.start(with: .init())
        appSettingsCoordinator = coordinator
    }

    func openMail(with dataCollector: EmailDataCollector, recipient: String, emailType: EmailType) {
        let logsComposer = LogsComposer(infoProvider: dataCollector)
        let mailViewModel = MailViewModel(logsComposer: logsComposer, recipient: recipient, emailType: emailType)

        mailPresenter.present(viewModel: mailViewModel)
    }

    func openGetTangemPay() {
        let dismissAction: Action<TangemPayOnboardingCoordinator.DismissOptions?> = { [weak self] _ in
            self?.tangemPayOnboardingCoordinator = nil
        }

        let coordinator = TangemPayOnboardingCoordinator(dismissAction: dismissAction)
        coordinator.start(with: .init(source: .other))
        tangemPayOnboardingCoordinator = coordinator
    }

    func openSupportChat(input: SupportChatInputModel) {
        Analytics.log(.chatScreenOpened)
        supportChatViewModel = SupportChatViewModel(input: input)
    }

    func openTOS() {
        tosViewModel = DetailsTOSViewModel()
    }

    func openScanCardManual() {
        safariManager.openURL(TangemBlogUrlBuilder().url(post: .scanCard))
    }

    func openShop() {
        safariManager.openURL(TangemShopUrlBuilder().url(utmCampaign: .users))
    }

    func openSocialNetwork(url: URL) {
        UIApplication.shared.open(url)
    }

    func openEnvironmentSetup() {
        let coordinator = EnvironmentSetupCoordinator(popToRootAction: popToRootAction)
        coordinator.start(with: .init())

        environmentSetupCoordinator = coordinator
    }

    func openLogs() {
        logsViewModel = .init()
    }

    func closeOnboarding() {
        modalOnboardingCoordinator = nil
    }
}

// MARK: - MobileBackupToUpgradeNeededRoutable

extension DetailsCoordinator: MobileBackupToUpgradeNeededRoutable {
    func dismissMobileBackupToUpgradeNeeded() {
        floatingSheetPresenter.removeActiveSheet()
    }
}
