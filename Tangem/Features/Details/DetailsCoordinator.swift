//
//  DetailsCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import UIKit

class DetailsCoordinator: CoordinatorObject {
    // MARK: - Dependencies

    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    @Injected(\.safariManager) private var safariManager: SafariManager
    @Injected(\.connectedDAppRepository) private var connectedDAppRepository: any WalletConnectConnectedDAppRepository

    // MARK: - Main view model

    @Published private(set) var detailsViewModel: DetailsViewModel?

    // MARK: - Child coordinators

    @Published var walletConnectCoordinator: WalletConnectCoordinator?
    @Published var userWalletSettingsCoordinator: UserWalletSettingsCoordinator?
    @Published var modalOnboardingCoordinator: OnboardingCoordinator?
    @Published var appSettingsCoordinator: AppSettingsCoordinator?
    @Published var createWalletSelectorCoordinator: CreateWalletSelectorCoordinator?
    @Published var importWalletSelectorCoordinator: ImportWalletSelectorCoordinator?

    // MARK: - Child view models

    @Published var mailViewModel: MailViewModel?
    @Published var supportChatViewModel: SupportChatViewModel?
    @Published var tosViewModel: TOSViewModel?
    @Published var environmentSetupCoordinator: EnvironmentSetupCoordinator?
    @Published var logsViewModel: LogsViewModel?
    @Published var tangemPayOfferViewModel: TangemPayOfferViewModel?

    // MARK: - Helpers

    @Published var modalOnboardingCoordinatorKeeper: Bool = false

    required init(dismissAction: @escaping Action<Void>, popToRootAction: @escaping Action<PopToRootOptions>) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: DetailsCoordinator.Options) {
        detailsViewModel = DetailsViewModel(coordinator: self)
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

    func openWalletSettings(options: UserWalletSettingsCoordinator.Options) {
        let dismissAction: Action<Void> = { [weak self] _ in
            self?.userWalletSettingsCoordinator = nil
        }

        let coordinator = UserWalletSettingsCoordinator(dismissAction: dismissAction, popToRootAction: popToRootAction)
        coordinator.start(with: options)
        userWalletSettingsCoordinator = coordinator
    }

    func openOnboardingModal(with input: OnboardingInput) {
        let dismissAction: Action<OnboardingCoordinator.OutputOptions> = { [weak self] result in
            self?.modalOnboardingCoordinator = nil

            if result.isSuccessful {
                self?.dismiss()
            }
        }

        let coordinator = OnboardingCoordinator(dismissAction: dismissAction)
        let options = OnboardingCoordinator.Options.input(input)
        coordinator.start(with: options)
        modalOnboardingCoordinator = coordinator
    }

    func openCreateWallet() {
        let dismissAction: Action<CreateWalletSelectorCoordinator.OutputOptions> = { [weak self] options in
            switch options {
            case .main:
                self?.dismiss()
            }
        }

        let coordinator = CreateWalletSelectorCoordinator(dismissAction: dismissAction)
        let inputOptions = CreateWalletSelectorCoordinator.InputOptions()
        coordinator.start(with: inputOptions)
        createWalletSelectorCoordinator = coordinator
    }

    func openImportWallet() {
        let dismissAction: Action<ImportWalletSelectorCoordinator.OutputOptions> = { [weak self] options in
            switch options {
            case .main:
                self?.dismiss()
            }
        }

        let coordinator = ImportWalletSelectorCoordinator(dismissAction: dismissAction)
        let inputOptions = ImportWalletSelectorCoordinator.InputOptions()
        coordinator.start(with: inputOptions)
        importWalletSelectorCoordinator = coordinator
    }

    func openAppSettings() {
        let coordinator = AppSettingsCoordinator(popToRootAction: popToRootAction)
        coordinator.start(with: .init())
        appSettingsCoordinator = coordinator
    }

    func openMail(with dataCollector: EmailDataCollector, recipient: String, emailType: EmailType) {
        let logsComposer = LogsComposer(infoProvider: dataCollector)
        mailViewModel = MailViewModel(logsComposer: logsComposer, recipient: recipient, emailType: emailType)
    }

    func openSupportChat(input: SupportChatInputModel) {
        Analytics.log(.chatScreenOpened)
        supportChatViewModel = SupportChatViewModel(input: input)
    }

    func openTOS() {
        tosViewModel = .init(bottomOverlayHeight: 0)
    }

    func openScanCardManual() {
        safariManager.openURL(TangemBlogUrlBuilder().url(post: .scanCard))
    }

    func openShop() {
        safariManager.openURL(AppConstants.getWebShopUrl(isExistingUser: true))
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

    func openTangemPayOfferViewModel() {
        tangemPayOfferViewModel = TangemPayOfferViewModel()
    }
}
